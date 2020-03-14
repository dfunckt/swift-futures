//
//  Locking.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public protocol LockingProtocol: AnyObject {
    /// Attempts to acquire the lock without blocking a thread's execution
    /// and returns a Boolean value that indicates whether the attempt was
    /// successful.
    func tryAcquire() -> Bool

    /// Attempts to acquire the lock, blocking a thread's execution until
    /// the lock can be acquired.
    func acquire()

    /// Relinquishes a previously acquired lock.
    func release()
}

extension LockingProtocol {
    @inlinable
    @inline(__always)
    public func sync<R>(_ fn: () throws -> R) rethrows -> R {
        acquire()
        defer { release() }
        return try fn()
    }

    @inlinable
    @inline(__always)
    public func trySync<R>(_ fn: () throws -> R) rethrows -> R? {
        guard tryAcquire() else { return nil }
        defer { release() }
        return try fn()
    }
}
