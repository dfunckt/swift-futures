//
//  ThreadExecutor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

public func assertOnThreadExecutor(_ executor: ThreadExecutor) {
    assert(ThreadExecutor.current._local == executor._local)
}

/// An executor that polls futures on the current thread.
///
/// `ThreadExecutor` is typically used to execute futures synchronously. Use
/// `wait()` to run the executor until all submitted futures complete or
/// `run(until:)` to run until a given future completes. Both methods block
/// the current thread when no more progress can be made.
///
/// `ThreadExecutor` can also be used to integrate Futures with other
/// asynchronous systems. For example, each worker thread in a thread pool
/// could maintain a private `ThreadExecutor` instance and run it on every
/// tick using `run()`. This method runs the executor until all possible
/// progress is made and then returns, without blocking the thread.
///
/// `ThreadExecutor` can optionally be initialized with limited capacity;
/// that is, it may be configured to have an upper bound on the number of
/// futures it tracks. Submitting a future that would result in the executor
/// exceeding capacity throws an error. You are encouraged to choose an
/// appropriate capacity for each use case, in order for the executor to
/// provide backpressure and limit memory usage or reduce latency. The
/// executor efficiently tracks its futures regardless of configured capacity;
/// that is, during each run it only polls futures that have signalled that
/// can make progress.
///
/// Each thread automatically gets an unbounded `ThreadExecutor` instance that
/// can be accessed via the `current` static property. Instances are lazily
/// created on first access and are stored in a thread local via `pthreads`.
/// Note that your code must still ensure it regularly calls `run()` or one of
/// the `wait` methods to run the executor.
///
/// `ThreadExecutor` is safe to use from one thread only, which is typically
/// the thread that created the instance. Running the executor from multiple
/// threads concurrently is undefined behavior and will most likely result in
/// a crash. The executor supports, however, submitting futures and concurrent
/// wakeups from any thread.
public struct ThreadExecutor {
    @usableFromInline typealias Parker = ThreadPark
    @usableFromInline typealias Scheduler = SharedScheduler<Void, Parker.Waker>
    @usableFromInline typealias Local = LocalExecutor<Scheduler, Parker>

    @usableFromInline let _capacity: Int
    @usableFromInline let _local: Local

    public init(capacity: Int = .max) {
        let parker = Parker()
        let scheduler = Scheduler(waker: parker.waker)
        _local = .init(scheduler: scheduler, parker: parker)
        _capacity = capacity
    }

    @inlinable
    public func run<F: FutureProtocol>(until future: inout F) -> F.Output {
        _local.run(until: &future)
    }

    /// Performs a single iteration over the list of ready-to-run futures,
    /// polling each one in turn. Returns when no more progress can be made.
    /// If the count of tracked futures drops to zero during the iteration,
    /// this method returns `true`.
    ///
    /// - Returns: `true` if the scheduler has completed running all futures
    ///     and is now empty.
    @inlinable
    public func run() -> Bool {
        _local.run()
    }

    @inlinable
    public func wait() {
        _local.wait()
    }
}

extension ThreadExecutor: ExecutorProtocol {
    /// The type of errors this executor may return from `trySubmit(_:)`.
    ///
    /// It only defines one error case, for the executor being at capacity.
    public enum Failure: Error {
        /// Denotes that the executor is at capacity.
        ///
        /// This is a transient error; subsequent submissions may succeed.
        case atCapacity
    }

    @inlinable
    public func trySubmit<F>(_ future: F) -> Result<Void, Failure>
        where F: FutureProtocol, F.Output == Void {
        if _local.scheduler.count == _capacity {
            return .failure(.atCapacity)
        }
        _local.scheduler.submit(future)
        _local.scheduler.waker.signal()
        return .success(())
    }
}

// MARK: Default executors

@usableFromInline let _currentThreadExecutor = ThreadLocal {
    ThreadExecutor()
}

extension ThreadExecutor {
    @inlinable
    public static var current: ThreadExecutor {
        _currentThreadExecutor.value
    }
}
