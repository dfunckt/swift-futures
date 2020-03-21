//
//  Executor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol that defines objects that execute futures.
///
/// Executors provide the context in which futures execute. This context may
/// be the current or a background thread, a Dispatch queue, a run loop, etc.
/// Executors typically enqueue submitted futures in a "ready to run" queue
/// and immediately return to the caller. This queue is later on consumed by
/// the executor in its execution context, driving futures to completion by
/// polling them. The polling algorithm is roughly:
///
///     var context = self.makeContext()
///     while var future = self.readyToRunQueue.pop() {
///         if future.poll(&context).isReady {
///             self.drop(future)
///         } else {
///             self.pendingFutures.push(future)
///         }
///     }
///
/// Futures that are ready to run are polled by the executor. If the future
/// returns that it completed (see `Poll`), it is let go by the executor,
/// which causes the future and associated resources to be released. Otherwise,
/// it is added into a "pending futures" registry. Before returning, the
/// future registers the context's waker (see `Context` and `WakerProtocol`)
/// to receive a notification when the external event the future is waiting on
/// fires. As a result of the notification, the future is added back into the
/// "ready to run" queue and the process repeats until the future signifies
/// completion.
///
/// Futures are submitted for execution via the `trySubmit(_:)` method of an
/// executor. Executors guarantee that submitted futures will be executed
/// asynchronously. In other words, `trySubmit(_:)` merely schedules the
/// future to be executed at some point in the future and returns to the caller
/// immediately. This is an important invariant that custom implementations
/// must also maintain, since it removes all concerns about reentrancy.
///
/// Executors may deny to receive the future, in which case `trySubmit(_:)`
/// returns an appropriate error of type `Failure`. This can be the case when
/// the executor is shutting down or is at capacity and needs to provide
/// backpressure. Executors that never fail, declare their `Failure` type as
/// `Never`.
///
/// This protocol makes no guarantees on the safety of concurrent calls to
/// `trySubmit(_:)`. Each executor implementation is free to declare support
/// for concurrent submissions, documenting the fact accordingly. This ambiguity
/// is not a problem in practice since you typically use concrete executor types
/// so you always know the specifics. The built-in `QueueExecutor` is an
/// executor that supports concurrent submissions.
public protocol ExecutorProtocol: AnyObject {
    /// The type of error the executor may fail with when submitting futures.
    associatedtype Failure: Error

    /// The maximum number of futures the executor can track concurrently.
    ///
    /// If the executor is unbounded, this property returns `Int.max`; see
    /// `isUnbounded`.
    var capacity: Int { get }

    /// Submits a future to be executed by this executor.
    ///
    /// The executor may deny to receive the future, in which case the
    /// returned result will contain an appropriate error. Typical cases where
    /// submission may fail is when the executor is shutting down or is at
    /// capacity and needs to provide backpressure. The latter case is expected
    /// to be a transient state which the executor will recover from and
    /// submission may be retried.
    func trySubmit<F>(_ future: F) -> Result<Void, Failure>
        where F: FutureProtocol, F.Output == Void
}

extension ExecutorProtocol {
    /// Returns a boolean denoting whether the executor can accept an
    /// unlimited number of futures.
    @inlinable
    public var isUnbounded: Bool {
        return capacity == Int.max
    }

    /// Submits a future to be executed by this executor.
    @inlinable
    public func submit<F: FutureProtocol>(_ future: F) throws where F.Output == Void {
        try trySubmit(future).get()
    }

    // MARK: -

    /// Submits a stream to be executed by this executor.
    ///
    /// The executor may deny to receive the stream, in which case the
    /// returned result will contain an appropriate error. Typical cases where
    /// submission may fail is when the executor is shutting down or is at
    /// capacity and needs to provide backpressure. The latter case is
    /// expected to be a transient state which the executor will recover from
    /// and submission may be retried.
    @inlinable
    public func trySubmit<S: StreamProtocol>(_ stream: S) -> Result<Void, Failure> where S.Output == Void {
        return trySubmit(stream.ignoreOutput())
    }

    /// Submits a stream to be executed by this executor.
    @inlinable
    public func submit<S: StreamProtocol>(_ stream: S) throws where S.Output == Void {
        try trySubmit(stream).get()
    }

    // MARK: -

    /// Submits a future into the executor and returns a handle that can be
    /// used to extract its result or cancel its execution.
    ///
    /// The handle is a cancellable future itself and can be safely sent and
    /// waited on any thread or submitted into another executor; see `Task`.
    @inlinable
    public func trySpawn<F: FutureProtocol>(_ future: F) -> Result<Task<F.Output>, Failure> {
        return Task.create(future: future, executor: self)
    }

    /// Submits a future into the executor and returns a handle that can be
    /// used to extract its result or cancel its execution.
    ///
    /// The handle is a cancellable future itself and can be safely sent and
    /// waited on any thread or submitted into another executor; see `Task`.
    @inlinable
    public func spawn<F: FutureProtocol>(_ future: F) throws -> Task<F.Output> {
        return try trySpawn(future).get()
    }
}

extension ExecutorProtocol where Failure == Never {
    @inlinable
    public func submit<F: FutureProtocol>(_ future: F) where F.Output == Void {
        try! trySubmit(future).get() // swiftlint:disable:this force_try
    }

    @inlinable
    public func submit<F: FutureProtocol>(_ future: F) where F.Output == Result<Void, Never> {
        try! trySubmit(future.ignoreOutput()).get() // swiftlint:disable:this force_try
    }

    @inlinable
    public func submit<S: StreamProtocol>(_ stream: S) where S.Output == Void {
        try! trySubmit(stream.ignoreOutput()).get() // swiftlint:disable:this force_try
    }

    @inlinable
    public func submit<S: StreamProtocol>(_ stream: S) where S.Output == Result<Void, Never> {
        try! trySubmit(stream.ignoreOutput()).get() // swiftlint:disable:this force_try
    }
}

extension ExecutorProtocol where Failure == Never {
    @inlinable
    public func spawn<F: FutureProtocol>(_ future: F) -> Task<F.Output> {
        try! trySpawn(future).get() // swiftlint:disable:this force_try
    }

    @inlinable
    public func spawn<S: StreamProtocol>(_ stream: S) -> Task<Void> where S.Output == Void {
        try! trySpawn(stream.ignoreOutput()).get() // swiftlint:disable:this force_try
    }
}

// MARK: -

/// A protocol that defines an object that can synchronously drive futures
/// to completion and can be waited on until it's empty.
///
/// Blocking executors must explicitly be asked to run, using the `run()`
/// method, to actually perform work.
public protocol BlockingExecutor: ExecutorProtocol {
    func makeContext() -> Context
    func execute(in context: inout Context) -> Bool
    func block()
}

extension BlockingExecutor {
    /// Runs the executor until all possible progress is made and returns a
    /// boolean denoting whether all submitted futures executed to completion.
    ///
    /// If this method returns `false`, indicating that the executor has still
    /// pending futures, you must call this method again some time in the
    /// future to ensure the futures tracked by the executor are driven to
    /// completion.
    @inlinable
    @discardableResult
    public func run() -> Bool {
        var context = makeContext()
        return execute(in: &context)
    }

    /// Runs the executor until the given future completes.
    @inlinable
    public func runUntil<F: FutureProtocol>(_ future: F) -> F.Output {
        var future = future
        var context = makeContext()
        while true {
            if case .ready(let result) = future.poll(&context) {
                return result
            }
            _ = execute(in: &context)
            block()
        }
    }

    /// Runs the executor until all submitted futures complete, blocking the
    /// current thread waiting for futures to become ready if no further
    /// progress can be made.
    ///
    /// Executor implementations must guarantee that when this method returns,
    /// the executor has run all submitted futures to completion and is empty.
    @inlinable
    public func wait() {
        var context = makeContext()
        while !execute(in: &context) {
            block()
        }
    }
}

// MARK: -

public protocol WakerProtocol: AnyObject {
    func signal()
}

public final class AnyWaker: WakerProtocol {
    private let _signalFn: () -> Void

    public init(_ signalHandler: @escaping () -> Void) {
        _signalFn = signalHandler
    }

    public func signal() {
        _signalFn()
    }
}
