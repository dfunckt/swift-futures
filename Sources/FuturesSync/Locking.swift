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

// MARK: -

public final class SharedValue<T, LockType: LockingProtocol> {
    @usableFromInline let _lock: LockType
    @usableFromInline var _value: T

    @inlinable
    public init(_ value: T, lock: LockType) {
        _value = value
        _lock = lock
    }

    @inlinable
    public func withMutableValue<R>(_ fn: (inout T) throws -> R) rethrows -> R {
        return try _lock.sync {
            try fn(&_value)
        }
    }

    @inlinable
    public func load() -> T {
        return withMutableValue { $0 }
    }

    @inlinable
    public func store(_ desired: T) {
        withMutableValue { $0 = desired }
    }

    @inlinable
    @discardableResult
    public func exchange(_ desired: T) -> T {
        return withMutableValue {
            let current = $0
            $0 = desired
            return current
        }
    }

    @inlinable
    public func take<Wrapped>() -> Wrapped? where T == Wrapped? {
        return withMutableValue {
            let current = $0
            $0 = nil
            return current
        }
    }
}

extension SharedValue where T: Equatable {
    @inlinable
    @discardableResult
    public func compareExchange(_ expected: T, _ desired: T) -> T? {
        return withMutableValue {
            let current = $0
            if current == expected {
                $0 = desired
                return nil
            }
            return current
        }
    }
}

extension SharedValue where LockType == UnfairLock {
    @inlinable
    public convenience init(_ value: T) {
        self.init(value, lock: .init())
    }
}
