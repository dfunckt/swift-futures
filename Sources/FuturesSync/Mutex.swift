//
//  Mutex.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public final class Mutex<Value, Lock: LockingProtocol> {
    @usableFromInline let _lock: Lock
    @usableFromInline var _value: Value

    @inlinable
    public init(_ value: Value, lock: Lock) {
        _value = value
        _lock = lock
    }

    @inlinable
    public var value: Value {
        _read {
            _lock.acquire()
            defer { _lock.release() }
            yield _value
        }
        _modify {
            _lock.acquire()
            defer { _lock.release() }
            yield &_value
        }
    }

    @inlinable
    @inline(__always)
    public func withMutableValue<R>(_ fn: (inout Value) throws -> R) rethrows -> R {
        return try _lock.sync {
            try fn(&_value)
        }
    }

    @inlinable
    public func load() -> Value {
        return withMutableValue { $0 }
    }

    @inlinable
    public func store(_ desired: Value) {
        withMutableValue { $0 = desired }
    }

    @inlinable
    @discardableResult
    public func exchange(_ desired: Value) -> Value {
        return withMutableValue {
            let current = $0
            $0 = desired
            return current
        }
    }

    @inlinable
    public func move<Wrapped>() -> Wrapped? where Value == Wrapped? {
        return withMutableValue {
            let current = $0
            $0 = nil
            return current
        }
    }
}

extension Mutex where Value: Equatable {
    @inlinable
    @discardableResult
    public func compareExchange(_ expected: Value, _ desired: Value) -> Value? {
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

extension Mutex where Lock == UnfairLock {
    @inlinable
    public convenience init(_ value: Value) {
        self.init(value, lock: .init())
    }
}
