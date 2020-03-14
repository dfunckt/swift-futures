//
//  Context.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

public struct Context {
    @usableFromInline let _waker: WakerProtocol

    @inlinable
    internal init(waker: WakerProtocol) {
        _waker = waker
    }

    @inlinable
    public var waker: WakerProtocol {
        return _waker
    }

    @inlinable
    public func usingWaker(_ waker: WakerProtocol) -> Context {
        return .init(waker: waker)
    }

    @inlinable
    public func yield<T>() -> Poll<T> {
        // signal the waker so that we're scheduled back
        // as soon as possible
        waker.signal()
        // give other threads a chance as well
        Atomic.preemptionYield(0)
        return .pending
    }
}
