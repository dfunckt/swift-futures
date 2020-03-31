//
//  SpinLock.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

// Prefer UnfairLock over this guy on Darwin;
// it's equally performant but safer.
public final class SpinLock: LockingProtocol {
    @usableFromInline var _flag: AtomicBool.RawValue = false

    @inlinable
    public init() {
        AtomicBool.initialize(&_flag, to: false)
    }

    @inlinable
    public func tryAcquire() -> Bool {
        return !AtomicBool.compareExchange(&_flag, false, true, order: .acquire)
    }

    @inlinable
    public func acquire() {
        var backoff = Backoff()
        while AtomicBool.compareExchangeWeak(&_flag, false, true, order: .acquire) {
            // discard result: we don't have anywhere else to yield to
            backoff.snooze()
        }
    }

    @inlinable
    public func release() {
        AtomicBool.compareExchange(&_flag, true, false, order: .release)
    }
}
