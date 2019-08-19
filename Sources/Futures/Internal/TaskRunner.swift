//
//  TaskRunner.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@usableFromInline
final class _TaskRunner {
    /// A user-displayable identifier. Can be useful for debugging.
    @usableFromInline let label: String

    private let _futures = _TaskScheduler<AnyFuture<Void>>()

    // Buffers futures that are submitted either externally via an executor
    // or internally by a future during polling via `Context`. On every tick,
    // the buffer is flushed into the scheduler in one go.
    @usableFromInline var _incoming = _AdaptiveQueue<AnyFuture<Void>>()

    @inlinable
    init(label: String) {
        self.label = label
    }

    /// The total number of futures currently being tracked.
    @usableFromInline
    var count: Int {
        return _incoming.count + _futures.count
    }

    /// Schedules the given future to be executed on the next tick.
    @inlinable
    func schedule<F>(_ future: F) where F: FutureProtocol, F.Output == Void {
        _incoming.push(.init(future))
    }

    /// Schedules the given future to be executed on the next tick.
    @inlinable
    func schedule(_ future: AnyFuture<Void>) {
        _incoming.push(future)
    }

    /// Performs a single iteration over the list of ready-to-run futures,
    /// polling each one in turn. Returns when no more progress can be made.
    /// If the count of tracked futures drops to zero during the iteration,
    /// this method returns `true`.
    @usableFromInline
    @discardableResult
    func run(_ context: inout Context) -> Bool {
        if !_incoming.isEmpty {
            // Schedule futures that have been submitted externally
            // via an executor since the last tick
            _futures.schedule(_incoming.consume().makeSequence())
        }

        _futures.register(context.waker)

        while true {
            let result = _futures.pollNext(&context)

            if !_incoming.isEmpty {
                // New futures have been submitted by the future;
                // schedule them and re-poll.
                _futures.schedule(_incoming.consume().makeSequence())
                continue
            }

            // No new futures enqueued, see if we're done.
            switch result {
            case .ready(.some):
                // There are more futures that are ready to be polled.
                continue
            case .ready(nil):
                // All futures have completed; scheduler is empty.
                return true
            case .pending:
                // No ready futures.
                return false
            }
        }
    }
}
