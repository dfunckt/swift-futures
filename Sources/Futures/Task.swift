//
//  Task.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

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
/// To create a task, use the `ExecutorProtocol.trySpawn(...)` method.
///
/// To cancel the task, invoke `cancel()` on it.
public final class Task<Output>: FutureProtocol, Cancellable {
    @usableFromInline
    struct _Inner {
        @usableFromInline let cancelled = AtomicBool(false)
        @usableFromInline let waker = AtomicWaker()
        @usableFromInline let promise = Promise<Output>()
    }

    @usableFromInline
    struct _RemoteFuture<F: FutureProtocol>: FutureProtocol where F.Output == Output {
        private let inner: _Inner
        private var future: F

        @usableFromInline
        init(inner: _Inner, future: F) {
            self.inner = inner
            self.future = future
        }

        @usableFromInline
        mutating func poll(_ context: inout Context) -> Poll<Void> {
            inner.waker.register(context.waker)
            if inner.cancelled.load() {
                return .ready
            }
            switch future.poll(&context) {
            case .ready(let result):
                inner.promise.resolve(result)
                return .ready
            case .pending:
                if inner.cancelled.load() {
                    return .ready
                }
                return .pending
            }
        }
    }

    // keep the executor alive while the task is kept alive
    @usableFromInline let executor: Any
    @usableFromInline let inner = _Inner()

    @inlinable
    init(executor: Any) {
        self.executor = executor
    }

    @inlinable
    deinit {
        cancel()
    }

    @inlinable
    func _wrap<F: FutureProtocol>(_ future: F) -> _RemoteFuture<F> {
        return .init(inner: inner, future: future)
    }

    @inlinable
    public func poll(_ context: inout Context) -> Poll<Output> {
        return inner.promise.poll(&context)
    }

    @inlinable
    public func cancel() {
        if !inner.cancelled.exchange(true) {
            inner.waker.signal()
        }
    }
}

// MARK: -

public struct Context {
    @usableFromInline let _runner: _TaskRunner
    @usableFromInline let _waker: WakerProtocol

    @inlinable
    init(runner: _TaskRunner, waker: WakerProtocol) {
        _runner = runner
        _waker = waker
    }

    @inlinable
    public var waker: WakerProtocol {
        return _waker
    }

    @inlinable
    public func withWaker(_ newWaker: WakerProtocol) -> Context {
        return .init(runner: _runner, waker: newWaker)
    }

    @inlinable
    public func submit<F: FutureProtocol>(_ future: F) where F.Output == Void {
        _runner.schedule(future)
    }

    @inlinable
    public func spawn<F: FutureProtocol>(_ future: F) -> Task<F.Output> {
        let task = Task<F.Output>(executor: _runner)
        let remote = task._wrap(future)
        _runner.schedule(remote)
        return task
    }

    @inlinable
    public func yield<T>() -> Poll<T> {
        // yielding a task is a form of spinning,
        // so give other threads a chance as well.
        Atomic.preemptionYield(0)
        _waker.signal()
        return .pending
    }
}
