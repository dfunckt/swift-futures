//
//  SpinLock.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

// Prefer UnfairLock over this guy, if available;
// it's equally performant but safer.
public final class SpinLock: LockingProtocol {
    @usableFromInline var _flag: AtomicBool.RawValue = false

    @inlinable
    public init() {
        Atomic.initialize(&_flag, to: false)
    }

    @inlinable
    public func tryAcquire() -> Bool {
        return !Atomic.compareExchange(&_flag, false, true, order: .acquire)
    }

    @inlinable
    public func acquire() {
        var backoff = Backoff()
        while Atomic.compareExchangeWeak(&_flag, false, true, order: .acquire) {
            backoff.yield()
        }
    }

    @inlinable
    public func release() {
        Atomic.compareExchange(&_flag, true, false, order: .release)
    }
}
