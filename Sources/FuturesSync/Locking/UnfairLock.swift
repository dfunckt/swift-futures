//
//  UnfairLock.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if !canImport(os)
public typealias UnfairLock = SpinLock
#else

import os

/// Low-level lock that allows waiters to block efficiently on contention.
///
/// There is no attempt at fairness or lock ordering, e.g. an unlocker can
/// potentially immediately reacquire the lock before a woken up waiter gets
/// an opportunity to attempt to acquire the lock. This may be advantageous
/// for performance reasons, but also makes starvation of waiters a possibility.
///
/// Backed by `os_unfair_lock`.
public final class UnfairLock: LockingProtocol {
    @usableFromInline var _lock = os_unfair_lock_s()

    @inlinable
    public init() {}

    @inlinable
    public func tryAcquire() -> Bool {
        return os_unfair_lock_trylock(&_lock)
    }

    @inlinable
    public func acquire() {
        os_unfair_lock_lock(&_lock)
    }

    @inlinable
    public func release() {
        os_unfair_lock_unlock(&_lock)
    }
}

#endif
