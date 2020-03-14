//
//  AtomicEnum.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

@inlinable
@_transparent
func _fromRawValue<R: RawRepresentable>(_ rawValue: R.RawValue, _: R.Type = R.self) -> R {
    let value = R(rawValue: rawValue)
    assert(value != nil, "\(rawValue) does not map to any case of \(R.self)")
    // swiftlint:disable:next force_unwrapping
    return value!
}

@inlinable
@_transparent
func _fromRawValue<O: OptionSet>(_ rawValue: O.RawValue, _: O.Type = O.self) -> O {
    return O(rawValue: rawValue)
}

@inlinable
@_transparent
func _toRawValue<R: RawRepresentable>(_ case: R) -> R.RawValue {
    return `case`.rawValue
}

// MARK: -

public final class AtomicEnum<R: RawRepresentable> where R.RawValue: _CAtomicInteger {
    public typealias Pointer = R.RawValue.AtomicPointer
    public typealias RawValue = R.RawValue.AtomicRawValue

    @usableFromInline var _storage: R.RawValue.AtomicRawValue = 0

    @inlinable
    init() {}
}

// MARK: - Int -

extension AtomicEnum where R.RawValue == Int {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == Int {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == Int {
    @_transparent
    public static func initialize(_ ptr: AtomicIntPointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicIntPointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicIntPointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == Int {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - Int8 -

extension AtomicEnum where R.RawValue == Int8 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == Int8 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == Int8 {
    @_transparent
    public static func initialize(_ ptr: AtomicInt8Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt8Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicInt8Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == Int8 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - Int16 -

extension AtomicEnum where R.RawValue == Int16 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == Int16 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == Int16 {
    @_transparent
    public static func initialize(_ ptr: AtomicInt16Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt16Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicInt16Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == Int16 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - Int32 -

extension AtomicEnum where R.RawValue == Int32 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == Int32 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == Int32 {
    @_transparent
    public static func initialize(_ ptr: AtomicInt32Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt32Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicInt32Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == Int32 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - Int64 -

extension AtomicEnum where R.RawValue == Int64 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == Int64 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == Int64 {
    @_transparent
    public static func initialize(_ ptr: AtomicInt64Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt64Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicInt64Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == Int64 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - UInt -

extension AtomicEnum where R.RawValue == UInt {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == UInt {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == UInt {
    @_transparent
    public static func initialize(_ ptr: AtomicUIntPointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUIntPointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicUIntPointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == UInt {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - UInt8 -

extension AtomicEnum where R.RawValue == UInt8 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == UInt8 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == UInt8 {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt8Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt8Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicUInt8Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == UInt8 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - UInt16 -

extension AtomicEnum where R.RawValue == UInt16 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == UInt16 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == UInt16 {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt16Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt16Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicUInt16Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == UInt16 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - UInt32 -

extension AtomicEnum where R.RawValue == UInt32 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == UInt32 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == UInt32 {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt32Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt32Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicUInt32Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == UInt32 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}

// MARK: - UInt64 -

extension AtomicEnum where R.RawValue == UInt64 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchange(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<R>,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: R,
        _ desired: R,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> R {
        return R.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicEnum where R: OptionSet, R.RawValue == UInt64 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

extension RawRepresentable where RawValue == UInt64 {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt64Pointer, to initialValue: Self) {
        ptr.initialize(to: _toRawValue(initialValue))
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.load(order: order))
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt64Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(_toRawValue(desired), order: order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public static func exchange(_ ptr: AtomicUInt64Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.exchange(_toRawValue(desired), order: order))
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ptr: AtomicUInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchange(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var rawValue = _toRawValue(expected.pointee)
        let result = ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(rawValue)
        return result
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var rawValue = _toRawValue(expected)
        ptr.compareExchangeWeak(
            &rawValue,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(rawValue)
    }
}

extension OptionSet where RawValue == UInt64 {
    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ptr: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAnd(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchOr(_ ptr: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchOr(_toRawValue(value), order: order))
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchXor(_ ptr: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchXor(_toRawValue(value), order: order))
    }
}
