//
//  LocalExecutor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

public struct LocalExecutor<Scheduler: SchedulerProtocol, Parker: ParkProtocol> where Scheduler.Output == Void {
    @usableFromInline let _parker: Parker
    @usableFromInline let _scheduler: Scheduler

    @inlinable
    public init(scheduler: Scheduler, parker: Parker) {
        _scheduler = scheduler
        _parker = parker
    }

    @inlinable
    public var scheduler: Scheduler {
        _scheduler
    }

    @inlinable
    public var parker: Parker {
        _parker
    }

    @inlinable
    public func run<F: FutureProtocol>(until future: inout F) -> F.Output {
        var context = Context(waker: _parker.waker)
        while true {
            switch future.poll(&context) {
            case .ready(let output):
                return output
            case .pending:
                _ = _scheduler.run()
                _parker.park()
            }
        }
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
        return _scheduler.run()
    }

    @inlinable
    public func wait() {
        while !_scheduler.run() {
            _parker.park()
        }
    }
}

extension LocalExecutor: ExecutorProtocol {
    public typealias Failure = Scheduler.Failure

    @inlinable
    public func trySubmit<F>(_ future: F) -> Result<Void, Failure>
        where F: FutureProtocol, F.Output == Void {
        return _scheduler.trySubmit(future)
    }
}

extension LocalExecutor: Equatable {
    public static func == (lhs: LocalExecutor, rhs: LocalExecutor) -> Bool {
        return lhs.scheduler === rhs.scheduler
    }
}
