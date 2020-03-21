//
//  Context.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

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
        return Task.create(future: future, runner: _runner)
    }

    @inlinable
    public func yield<T>() -> Poll<T> {
        _waker.signal()
        // yielding a task is a form of spinning,
        // so give other threads a chance as well.
        Atomic.preemptionYield(0)
        return .pending
    }
}
