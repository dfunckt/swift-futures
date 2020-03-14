//
//  Scheduler.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol that defines objects that can interface with executors and
/// `ScheduledTask` to drive futures to completion.
///
/// Conforming types must ensure that their implementation for
/// `didReceiveSignal(_:)` is thread-safe.
public protocol SchedulerProtocol: AnyObject {
    /// The type of output produced by tasks managed by this scheduler.
    associatedtype Output

    /// The type of error the scheduler may fail with when tasks are submitted.
    associatedtype Failure: Error

    typealias Task = ScheduledTask<Self>

    // MARK: Executor callbacks

    /// The "entry point" of tasks into the scheduler.
    ///
    /// Submitted futures must be wrapped into `ScheduledTask` instances and
    /// arranged to be polled the soonest possible, typically by adding them
    /// into a "ready queue" that is consumed by consecutive calls to `next()`.
    func trySubmit(_ future: @escaping Task.Future) -> Result<Void, Failure>

    /// Returns the number of tasks bound on this scheduler.
    var count: Int { get }

    /// Removes and returns the next runnable task from the scheduler's
    /// "ready queue".
    func next() -> Task?

    // MARK: Task callbacks

    /// Associate the given task with this scheduler.
    ///
    /// Task calls this method on this scheduler if it is the one that polls
    /// it for the first time. Once bound, a task stays associated with its
    /// scheduler for its whole lifetime. To unbind the task, this scheduler
    /// must call `cancel()` on the task.
    func bind(_ task: Task)

    /// Remove the given task from this scheduler.
    ///
    /// Task calls this method after its future completes. The scheduler must
    /// call `release()` on the task but is otherwise free to decide whether
    /// to unbind the task or put it aside for reuse. To unbind the task, the
    /// scheduler must call `cancel()` on the task after releasing it.
    ///
    /// The `scheduler` argument is the scheduler that actually polled the
    /// task. This allows schedulers to transfer tasks between instances and,
    /// potentially, threads.
    func release(_ task: Task, from scheduler: Self)

    /// Notify this scheduler that the given task is runnable and should be
    /// polled as soon as possible.
    ///
    /// Task calls this method when it is signalled by its future during
    /// `poll()`. Like in `release(_:from:)`, the `scheduler` argument is the
    /// scheduler that actually polled the task.
    func schedule(_ task: Task, from scheduler: Self)

    /// Notify this scheduler that the given task is runnable and should be
    /// polled as soon as possible.
    ///
    /// Task calls this method when it is signalled by its future, potentially
    /// on a thread other than the one that owns this scheduler.
    func didReceiveSignal(_ task: Task)
}

extension SchedulerProtocol {
    @inlinable
    public var isEmpty: Bool {
        @_transparent get { count == 0 }
    }

    @_transparent
    public func pollNext() -> Output? {
        if let task = next() {
            return task.poll(scheduler: self)
        }
        return nil
    }
}

extension SchedulerProtocol where Output == Void {
    /// Performs a single iteration over the list of ready-to-run futures,
    /// polling each one in turn. Returns when no more progress can be made.
    /// If the count of tracked futures drops to zero during the iteration,
    /// this method returns `true`.
    ///
    /// - Returns: `true` if the scheduler has completed running all futures
    ///     and is now empty.
    @_transparent
    public func run() -> Bool {
        while let task = next() {
            task.poll(scheduler: self)
        }
        return isEmpty
    }
}

extension SchedulerProtocol {
    @_transparent
    public func trySubmit<F>(_ future: F) -> Result<Void, Failure> where F: FutureProtocol, F.Output == Output {
        var future = future
        return trySubmit { future.poll(&$0) }
    }

    /// - Returns: The number of submitted tasks.
    @_transparent
    public func trySubmit<S: Sequence>(_ futures: S) -> Result<Int, Failure> where S.Element: FutureProtocol, S.Element.Output == Output {
        var count = 0
        for future in futures {
            if case .failure(let error) = trySubmit(future) {
                return .failure(error)
            }
            count += 1
        }
        return .success(count)
    }
}

extension SchedulerProtocol where Failure == Never {
    @_transparent
    public func submit<F>(_ future: F) where F: FutureProtocol, F.Output == Output {
        try! trySubmit(future).get()
    }

    /// - Returns: The number of submitted tasks.
    @discardableResult
    @_transparent
    public func submit<S: Sequence>(_ futures: S) -> Int where S.Element: FutureProtocol, S.Element.Output == Output {
        try! trySubmit(futures).get()
    }
}
