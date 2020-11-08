//
//  QueueExecutor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Dispatch
import FuturesSync

public func assertOnQueueExecutor(_ executor: QueueExecutor) {
    dispatchPrecondition(condition: .onQueue(executor.queue))
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
    public enum Failure: Error {
        case shutdown
    }

    @usableFromInline let _scheduler: SharedScheduler<Void, _QueueWaker>

    @inlinable
    public convenience init(label: String, qos: DispatchQoS = .default) {
        let label = "futures.queue-executor(\(label))"
        self.init(queue: .init(label: label, qos: qos))
    }

    @inlinable
    public convenience init(targetQueue: DispatchQueue) {
        let label = "futures.queue-executor(\(targetQueue.label))"
        let queue = DispatchQueue(label: label, target: targetQueue)
        self.init(queue: queue)
    }

    @usableFromInline
    init(queue: DispatchQueue) {
        _scheduler = .init(waker: .init(queue))
        _scheduler.waker.setSignalHandler { [weak self] in
            self?._scheduler.run() ?? true
        }
    }

    deinit {
        cancel()
    }

    @inlinable
    internal var queue: DispatchQueue {
        _scheduler.waker.queue
    }

    public var label: String {
        return _scheduler.waker.queue.label
    }

    /// Schedules the given future to be executed by this executor.
    ///
    /// This method can be called from any thread.
    @inlinable
    public func trySubmit<F: FutureProtocol>(_ future: F) -> Result<Void, Failure> where F.Output == Void {
        _scheduler.submit(future)
        _scheduler.waker.signal()
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
        _scheduler.waker.suspend()
    }

    /// Resumes execution of futures.
    ///
    /// Calling this method on an executor that is not suspended traps at
    /// runtime.
    ///
    /// This method can be called from any thread.
    public func resume() {
        _scheduler.waker.resume()
    }

    /// Cancels further execution of futures.
    ///
    /// This method can be called from any thread.
    public func cancel() {
        _scheduler.waker.cancel()
    }

    /// Blocks the current thread until all futures tracked by this executor
    /// complete.
    ///
    /// This method can be called from any thread.
    @inlinable
    public func wait() {
        _scheduler.waker.wait()
    }
}

extension QueueExecutor: CustomDebugStringConvertible {
    public var debugDescription: String {
        "QueueExecutor(label: \(label), scheduler: \(String(reflecting: _scheduler)))"
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

@usableFromInline
final class _QueueWaker: WakerProtocol {
    @usableFromInline internal let queue: DispatchQueue

    private let _source: DispatchSourceUserDataAdd
    private let _cond = PosixConditionLock()
    private var _done = false

    @usableFromInline
    init(_ queue: DispatchQueue) {
        self.queue = queue
        _source = DispatchSource.makeUserDataAddSource(queue: queue)
    }

    func setSignalHandler(_ fn: @escaping () -> Bool) {
        _source.setEventHandler {
            let result = fn()
            self._cond.sync {
                self._done = result
                if result {
                    self._cond.broadcast()
                }
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
        _cond.sync {
            self._done = true
            self._cond.broadcast()
        }
    }

    @usableFromInline
    func signal() {
        _source.add(data: 1)
    }

    @usableFromInline
    func wait() {
        _source.add(data: 1)
        _cond.sync {
            while !self._done {
                self._cond.wait()
            }
        }
    }
}
