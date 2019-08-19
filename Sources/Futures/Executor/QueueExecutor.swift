//
//  QueueExecutor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Dispatch
import FuturesSync

public func assertOnQueueExecutor(_ executor: QueueExecutor) {
    dispatchPrecondition(condition: .onQueue(executor._queue))
}

public func assertOnMainQueueExecutor() {
    assertOnQueueExecutor(QueueExecutor.main)
}

/// A thread-safe unbounded executor backed by a serial Dispatch queue.
///
/// Submitting futures into this executor from any thread is a safe operation.
///
/// Dropping the last reference to the executor, causes it to be deallocated.
/// Any pending tasks tracked by the executor at the time are destroyed as well.
public final class QueueExecutor: ExecutorProtocol, Cancellable {
    fileprivate let _queue: DispatchQueue
    private let _runner: _TaskRunner
    private let _waker: _QueueWaker
    private let _incoming = AtomicUnboundedMPSCQueue<AnyFuture<Void>>()
    private var _complete = false

    public convenience init(label: String, qos: DispatchQoS = .default) {
        let label = "futures.queue-executor(\(label))"
        self.init(queue: .init(label: label, qos: qos))
    }

    public convenience init(targetQueue: DispatchQueue) {
        let label = "futures.queue-executor(\(targetQueue.label))"
        let queue = DispatchQueue(label: label, target: targetQueue)
        self.init(queue: queue)
    }

    private init(queue: DispatchQueue) {
        _queue = queue
        _runner = .init(label: queue.label)
        _waker = .init(queue)
        _waker.setSignalHandler { [weak self] in
            guard let self = self else {
                return true
            }
            return self._run()
        }
    }

    @usableFromInline
    func _run() -> Bool {
        var context = Context(runner: _runner, waker: _waker)
        while true {
            // schedule up to an arbitrary limit so that we don't end up
            // only scheduling futures and making no progress.
            var i = 0
            while let future = _incoming.pop(), i < 2_048 {
                _runner.schedule(future)
                i += 1
            }

            let completed = _runner.run(&context)

            if _incoming.isEmpty {
                return completed
            }
        }
    }

    deinit {
        cancel()
    }

    public var label: String {
        return _queue.label
    }

    public var capacity: Int {
        return Int.max
    }

    /// Schedules the given future to be executed by this executor.
    ///
    /// This method can be called from any thread.
    public func trySubmit<F: FutureProtocol>(_ future: F) -> Result<Void, Never> where F.Output == Void {
        _incoming.push(.init(future))
        _waker.signal()
        return .success(())
    }

    /// Suspends execution of futures.
    ///
    /// While suspended, the executor buffers submitted futures but does not
    /// schedules them for execution until it is resumed again.
    ///
    /// This method can be called multiple times. Like a counting semaphore,
    /// each call internally increments a counter which is decremented by calls
    /// to `resume()`. When this counter drops back to zero, the executor
    /// resumes operation.
    ///
    /// This method can be called from any thread.
    public func suspend() {
        _waker.suspend()
    }

    /// Resumes execution of futures.
    ///
    /// Calling this method on an executor that is not suspended traps at
    /// runtime.
    ///
    /// This method can be called from any thread.
    public func resume() {
        _waker.resume()
    }

    /// Cancels further execution of futures.
    ///
    /// This method can be called from any thread.
    public func cancel() {
        _waker.cancel()
    }

    /// Blocks the current thread until all futures tracked by this executor
    /// complete.
    ///
    /// This method can be called from any thread.
    public func wait() {
        _waker.wait()
    }
}

// MARK: Default executors

extension QueueExecutor {
    /// An executor backed by the main Dispatch queue.
    public static let main = QueueExecutor(targetQueue: .main)

    /// An executor backed by the default QoS global Dispatch queue.
    public static let global = QueueExecutor(targetQueue: .global())

    /// An executor backed by the "user interactive" QoS global Dispatch queue.
    public static let userInteractive = QueueExecutor(targetQueue: .global(qos: .userInteractive))

    /// An executor backed by the "user initiated" QoS global Dispatch queue.
    public static let userInitiated = QueueExecutor(targetQueue: .global(qos: .userInitiated))

    /// An executor backed by the "utility" QoS global Dispatch queue.
    public static let utility = QueueExecutor(targetQueue: .global(qos: .utility))

    /// An executor backed by the "background" QoS global Dispatch queue.
    public static let background = QueueExecutor(targetQueue: .global(qos: .background))
}

// MARK: - Private -

private final class _QueueWaker: WakerProtocol {
    private let _source: DispatchSourceUserDataAdd
    private let _waiters = AtomicUnboundedMPSCQueue<DispatchSemaphore>()

    init(_ queue: DispatchQueue) {
        _source = DispatchSource.makeUserDataAddSource(queue: queue)
    }

    deinit {
        notifyWaiters()
    }

    func setSignalHandler(_ fn: @escaping () -> Bool) {
        _source.setEventHandler {
            if fn() {
                self.notifyWaiters()
            }
        }
        _source.activate()
    }

    func suspend() {
        _source.suspend()
    }

    func resume() {
        _source.resume()
    }

    func cancel() {
        _source.cancel()
    }

    func signal() {
        _source.add(data: 1)
    }

    func wait() {
        let sema = DispatchSemaphore(value: 0)
        _waiters.push(sema)
        sema.wait()
    }

    private func notifyWaiters() {
        var waiters = [DispatchSemaphore]()
        while let sema = _waiters.pop() {
            waiters.append(sema)
        }
        for sema in waiters {
            sema.signal()
        }
    }
}
