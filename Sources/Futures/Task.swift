//
//  Task.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

// set to `false` to replace Task with a simple
// lock-based implementation that is useful for
// debugging.
#if true

/// A handle to a unit of work that is executing in an executor.
///
/// In Futures, task is both a high-level concept and a type. As a concept, it
/// is the outermost future that is submitted into an executor for execution.
/// As a type, it is a handle to the conceptual task, which can be used to
/// extract the result of the computation or cancel it altogether.
///
/// Tasks are futures themselves and can be seamlessly combined with other tasks
/// or futures.
///
/// `Task` guarantees that:
///
/// - the wrapped future is cancelled if the task is dropped.
/// - the wrapped future is destroyed on the executor's context it was
///   submitted on.
/// - the executor is kept alive for as long as the task itself is kept alive.
///
/// To create a task, use the `ExecutorProtocol.trySpawn(_:)` method.
///
/// To cancel the task, call `cancel()` on the instance. Cancellation also
/// happens automatically when all references to the task are dropped.
public final class Task<T> {
    private let _inner: _Inner
    private let _executor: Any

    private init(inner: _Inner, executor: Any) {
        _inner = inner
        _executor = executor
    }

    deinit {
        _cancel()
    }

    @usableFromInline
    internal static func create<F: FutureProtocol, E: ExecutorProtocol>(
        future: F,
        executor: E
    ) -> Result<Task<F.Output>, E.Failure> where F.Output == T {
        let inner = _Inner()
        let remote = _RemoteFuture(inner: inner, future: future)
        return executor.trySubmit(remote).map {
            .init(inner: inner, executor: executor)
        }
    }
}

extension Task: Cancellable {
    public var isCancelled: Bool {
        return State.load(&_inner.state, order: .relaxed).contains(.cancelled)
    }

    public func cancel() {
        _cancel()
    }
}

extension Task: FutureProtocol {
    public enum Error: Swift.Error {
        case cancelled
    }

    public typealias Output = Result<T, Error>

    public func poll(_ context: inout Context) -> Poll<Output> {
        return _poll(&context)
    }
}

// MARK: - Task Private -

/// Notes about the implementation:
///
/// We synchronize between (at most) three threads:
///
/// - the *remote future* thread, that's polling the wrapped future to
///   store its output.
/// - the *task handle* thread, that's polling to read the output.
/// - the *canceller* thread, that signals that the task must be cancelled.
///
/// There are three resources these threads compete for:
///
/// - the future's output: set by the remote future; read by the task handle.
/// - the task handle's waker: set by the task handle; read by both the
///   remote future and the canceller.
/// - the remote future's waker: set by the remote future; read by both the
///   task handle and the canceller.
///
/// Resolving the future
/// ====================
///
/// The task handle synchronizes with the remote future for access to the
/// output as follows:
///
///  - the remote: stores output, sets `resolved` flag, signals handle waker
///  - the handle: registers waker, reads `resolved` flag, reads `output` if
///    flag is set
///
/// To register its waker, the task handle uses the `polling` flag as a lock.
/// For as long as that flag is set, the remote future does not touch the task
/// handle waker. To avoid losing the notification that may happen while the
/// `polling` flag is set, the task handle then checks for the presence of the
/// `resolved` flag and, if it's set, reads the `output`.
///
/// Cancellation
/// ============
///
/// At any moment, another thread may call `cancel()` to cancel the task.
/// Cancellation first toggles the `cancelled` flag, and then goes on to
/// signal the remote future and task handle wakers. Cancellation has the
/// highest priority of all possible states, so the moment the remote
/// future and the task handle observe the fact, they bail out.
///
/// Synchronizing access of the canceller to the remote future waker is
/// straightforward. The remote future, similarly to the task handle, sets
/// a flag, stores its waker, unsets the flag and checks for cancellation.
/// The canceller, before accessing the waker, checks for the presence of
/// that flag and, if it's not set, signals the waker.
///
/// Synchronizing access of the canceller to the task handle waker is even
/// easier, even though the canceller competes with the remote future that
/// may be trying to signal completion to the task handle at the same time.
/// This is because the remote future will only touch the task handle waker
/// if the `polling` flag is not present when it toggles the `resolved` flag.
/// So the canceller merely has to check for the absense of *both* these
/// flags. If either flag is set, it is guaranteed that the task handle will
/// observe the cancellation either because it's currently not idle, or has
/// been signalled already by the remote future.
private extension Task {
    /// A bitset of the various states the task can be in.
    private struct State: AtomicBitset {
        let rawValue: AtomicUInt.RawValue
        static var pending: State { 0 }
        static var polling: State { 0b0001 }
        static var registering: State { 0b0010 }
        static var resolved: State { 0b0100 }
        static var cancelled: State { 0b1000 }
    }

    /// Container for state shared between the task handle and the remote
    /// future.
    ///
    /// Storing shared data in an intermediate object instead of the task
    /// handle itself, means the remote future need not keep a reference to
    /// the handle, which allows us to support automatic cancellation when
    /// the handle is dropped.
    private final class _Inner {
        var state: State.RawValue = 0
        var remoteWaker: WakerProtocol? // used to signal cancellation
        var handleWaker: WakerProtocol? // used to signal completion and cancellation
        var output: T! // slot to store the future output on completion
        // swiftlint:disable:previous implicitly_unwrapped_optional

        init() {
            State.initialize(&state, to: .pending)
        }
    }

    private func _poll(_ context: inout Context) -> Poll<Output> {
        // Try to set the waker first thing.
        // Switch on the .polling bit before doing so. Both the remote
        // future and the canceller will not touch the waker while it's on.
        switch State.compareExchange(&_inner.state, .pending, .polling) {
        case .pending:
            // Lock acquired; set the waker
            _inner.handleWaker = context.waker

            // Try to release the lock by switching the bit off. If this
            // fails it must be either because the remote future resolved
            // or the task was cancelled in the meantime.
            switch State.compareExchange(&_inner.state, .polling, .pending) {
            case .polling:
                return .pending
            case let actual:
                if actual.contains(.cancelled) {
                    return .ready(.failure(.cancelled))
                }
                assert(actual.contains(.resolved), "expected resolved; found \(actual)")
                // swiftlint:disable:next force_unwrapping
                return .ready(.success(_inner.output.move()!))
            }

        case .registering:
            // The remote future is registering its waker.
            // Check back in a bit.
            return context.yield()

        case let actual:
            if actual.contains(.cancelled) {
                return .ready(.failure(.cancelled))
            }
            if actual.contains(.resolved) {
                // We're done; return the output
                // swiftlint:disable:next force_unwrapping
                return .ready(.success(_inner.output.move()!))
            }
            assert(actual == .polling, "expected polling; found \(actual)")
            fatalError("concurrent attempt to poll task handle")
        }
    }

    private enum _RemoteFuture<F: FutureProtocol>: FutureProtocol where F.Output == T {
        case pending(_Inner, F)
        case done

        init(inner: _Inner, future: F) {
            self = .pending(inner, future)
        }

        mutating func poll(_ context: inout Context) -> Poll<Void> {
            switch self {
            case .pending(let inner, var future):
                // Check for cancellation before polling the future.
                // Order is `.relaxed` as we don't really synchronize
                // anything here.
                if State.load(&inner.state, order: .relaxed).contains(.cancelled) {
                    self = .done
                    return .ready(())
                }

                // Poll the future and if it's ready, store away the
                // output and toggle the .resolved bit.
                switch future.poll(&context) {
                case .ready(let output):
                    inner.output = output
                    let curr = State.fetchOr(&inner.state, .resolved)
                    assert(
                        curr == .pending ||
                            curr == .polling ||
                            curr == .cancelled ||
                            curr == .cancelled | .polling,
                        "expected pending, polling or cancelled; found \(curr)"
                    )
                    if !curr.contains(.polling) {
                        // The task handle isn't in the critical section
                        // trying to set its waker.
                        inner.handleWaker?.signal()
                    }
                    self = .done
                    return .ready(())

                case .pending:
                    while true {
                        // Try to register our waker so that the canceller
                        // can signal us on cancellation.
                        switch State.compareExchange(&inner.state, .pending, .registering) {
                        case .pending:
                            // Lock acquired; set the waker
                            inner.remoteWaker = context.waker

                            // Toggle the bit back off and check whether the
                            // task has been cancelled.
                            if State.fetchXor(&inner.state, .registering).contains(.cancelled) {
                                self = .done
                                return .ready(())
                            }
                            self = .pending(inner, future)
                            return .pending
                        case .polling:
                            // The task handle is registering its waker.
                            // Just retry.
                            Atomic.hardwarePause()
                            continue
                        case let actual:
                            assert(actual == .cancelled, "expected cancelled; found \(actual)")
                            self = .done
                            return .ready(())
                        }
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }

    private func _cancel() {
        let curr = State.fetchOr(&_inner.state, .cancelled)
        if curr.contains(.cancelled) || curr.contains(.resolved) {
            // Either already cancelled or resolved; there's no need to
            // notify anyone.
            return
        }
        if !curr.contains(.registering) {
            // The remote future is not in the critical section
            // trying to set its waker, so it's safe to access it.
            _inner.remoteWaker?.signal()
        }
        if !curr.contains(.polling | .resolved) {
            // The task handle and the remote future are not in the
            // critical section trying to set and get the task waker
            // respectively, so it's safe to access it.
            _inner.handleWaker?.signal()
        }
    }
}

#else
private let _warnBlockingTask: Void = {
    print("WARNING: using blocking Task")
}()

/// :nodoc:
public final class Task<T>: FutureProtocol, Cancellable {
    public enum Error: Swift.Error {
        case cancelled
    }

    private let _inner: _Inner
    private let _executor: Any

    private init(inner: _Inner, executor: Any) {
        _inner = inner
        _executor = executor
        _warnBlockingTask
    }

    deinit {
        cancel()
    }

    @usableFromInline
    internal static func create<E: ExecutorProtocol, F: FutureProtocol>(
        future: F,
        executor: E
    ) -> Result<Task<F.Output>, E.Failure> where F.Output == T {
        let inner = _Inner()
        let remote = _RemoteFuture(inner: inner, future: future)
        return executor.trySubmit(remote).map {
            .init(inner: inner, executor: executor)
        }
    }

    public func cancel() {
        // Toggle the flag and signal the wakers.
        if !AtomicBool.exchange(&_inner.cancelled, true) {
            let wakers: (WakerProtocol?, WakerProtocol?) = _inner.sync {
                ($0.remoteWaker.move(), $0.handleWaker.move())
            }
            wakers.0?.signal()
            wakers.1?.signal()
        }
    }

    public typealias Output = Result<T, Error>

    public func poll(_ context: inout Context) -> Poll<Output> {
        if AtomicBool.load(&_inner.cancelled) {
            return .ready(.failure(.cancelled))
        }
        let output: T? = _inner.sync {
            $0.handleWaker = context.waker
            return $0.output.move()
        }
        if let output = output {
            return .ready(.success(output))
        }
        return .pending
    }

    private final class _Inner {
        var cancelled: AtomicBool.RawValue = false

        // The following must only be accessed with `_lock` held.
        @usableFromInline let _lock = UnfairLock()
        var remoteWaker: WakerProtocol?
        var handleWaker: WakerProtocol?
        var output: T! // swiftlint:disable:this implicitly_unwrapped_optional

        init() {
            AtomicBool.initialize(&cancelled, to: false)
        }

        @inlinable
        @inline(__always)
        func sync<R>(_ fn: (_Inner) -> R) -> R {
            return _lock.sync { fn(self) }
        }
    }

    private enum _RemoteFuture<F: FutureProtocol>: FutureProtocol where F.Output == T {
        case pending(_Inner, F)
        case done

        init(inner: _Inner, future: F) {
            self = .pending(inner, future)
        }

        mutating func poll(_ context: inout Context) -> Poll<Void> {
            switch self {
            case .pending(let inner, var future):
                if AtomicBool.load(&inner.cancelled) {
                    self = .done
                    return .ready(())
                }

                switch future.poll(&context) {
                case .ready(let output):
                    let waker: WakerProtocol? = inner.sync {
                        $0.output = output
                        return $0.handleWaker.move()
                    }
                    waker?.signal()
                    self = .done
                    return .ready(())
                case .pending:
                    // Register the waker before checking the cancellation
                    // flag. The task does the inverse; first toggles the
                    // flag, then signals the waker.
                    inner.sync {
                        $0.remoteWaker = context.waker
                    }
                    if AtomicBool.load(&inner.cancelled) {
                        self = .done
                        return .ready(())
                    }
                    self = .pending(inner, future)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
#endif
