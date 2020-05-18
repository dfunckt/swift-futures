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
        return !AtomicBool.exchange(&_flag, true, order: .acquire)
    }

    @inlinable
    public func acquire() {
        var backoff = Backoff()
        while AtomicBool.compareExchangeWeak(&_flag, false, true, order: .acquire) {
            backoff.snooze()
        }
    }

    @inlinable
    public func release() {
        AtomicBool.store(&_flag, false, order: .release)
    }
}
