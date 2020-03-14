//
//  AtomicValue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

// MARK: - Bool -

extension Swift.Bool: _CAtomicValue {
    public typealias AtomicRawValue = CAtomicBool
    public typealias AtomicPointer = AtomicBoolPointer
}

public final class AtomicBool {
    public typealias Pointer = AtomicBoolPointer
    public typealias RawValue = CAtomicBool

    @usableFromInline var _storage = false

    @inlinable
    init() {}
}

extension AtomicBool {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicBool.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicBool.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicBool.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicBool.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicBool.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicBool.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicBool.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicBool.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicBool.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicBool.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicBool.fetchXor(&_storage, value, order: order)
    }
}

extension AtomicBool {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Bool) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Bool {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Bool, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Bool>,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Bool,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Bool>,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Bool,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return ptr.fetchXor(value, order: order)
    }
}

// MARK: - Int -

extension Swift.Int: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt
    public typealias AtomicPointer = AtomicIntPointer
}

public final class AtomicInt {
    public typealias Pointer = AtomicIntPointer
    public typealias RawValue = CAtomicInt

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicInt {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicInt.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicInt.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicInt {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Int) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Int, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int>,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int>,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - Int8 -

extension Swift.Int8: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt8
    public typealias AtomicPointer = AtomicInt8Pointer
}

public final class AtomicInt8 {
    public typealias Pointer = AtomicInt8Pointer
    public typealias RawValue = CAtomicInt8

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicInt8 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicInt8.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicInt8.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt8.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt8.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt8.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt8.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt8.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicInt8 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Int8) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int8 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Int8, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int8>,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int8,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int8 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int8>,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int8,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int8 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - Int16 -

extension Swift.Int16: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt16
    public typealias AtomicPointer = AtomicInt16Pointer
}

public final class AtomicInt16 {
    public typealias Pointer = AtomicInt16Pointer
    public typealias RawValue = CAtomicInt16

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicInt16 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicInt16.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicInt16.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt16.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt16.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt16.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt16.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt16.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicInt16 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Int16) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int16 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Int16, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int16>,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int16,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int16 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int16>,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int16,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int16 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - Int32 -

extension Swift.Int32: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt32
    public typealias AtomicPointer = AtomicInt32Pointer
}

public final class AtomicInt32 {
    public typealias Pointer = AtomicInt32Pointer
    public typealias RawValue = CAtomicInt32

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicInt32 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicInt32.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicInt32.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt32.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt32.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt32.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt32.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt32.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicInt32 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Int32) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int32 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Int32, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int32>,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int32,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int32 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int32>,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int32,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int32 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - Int64 -

extension Swift.Int64: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt64
    public typealias AtomicPointer = AtomicInt64Pointer
}

public final class AtomicInt64 {
    public typealias Pointer = AtomicInt64Pointer
    public typealias RawValue = CAtomicInt64

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicInt64 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicInt64.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicInt64.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt64.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt64.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicInt64.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicInt64.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicInt64.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicInt64 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: Int64) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int64 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: Int64, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int64>,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int64,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int64 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<Int64>,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: Int64,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int64 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - UInt -

extension Swift.UInt: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt
    public typealias AtomicPointer = AtomicUIntPointer
}

public final class AtomicUInt {
    public typealias Pointer = AtomicUIntPointer
    public typealias RawValue = CAtomicUInt

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicUInt {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicUInt.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicUInt.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicUInt {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: UInt) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: UInt, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt>,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt>,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - UInt8 -

extension Swift.UInt8: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt8
    public typealias AtomicPointer = AtomicUInt8Pointer
}

public final class AtomicUInt8 {
    public typealias Pointer = AtomicUInt8Pointer
    public typealias RawValue = CAtomicUInt8

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicUInt8 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicUInt8.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicUInt8.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt8.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt8.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt8.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt8.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt8.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicUInt8 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: UInt8) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt8 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: UInt8, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt8>,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt8,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt8 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt8>,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt8,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt8 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - UInt16 -

extension Swift.UInt16: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt16
    public typealias AtomicPointer = AtomicUInt16Pointer
}

public final class AtomicUInt16 {
    public typealias Pointer = AtomicUInt16Pointer
    public typealias RawValue = CAtomicUInt16

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicUInt16 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicUInt16.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicUInt16.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt16.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt16.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt16.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt16.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt16.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicUInt16 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: UInt16) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt16 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: UInt16, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt16>,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt16,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt16 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt16>,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt16,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt16 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - UInt32 -

extension Swift.UInt32: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt32
    public typealias AtomicPointer = AtomicUInt32Pointer
}

public final class AtomicUInt32 {
    public typealias Pointer = AtomicUInt32Pointer
    public typealias RawValue = CAtomicUInt32

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicUInt32 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicUInt32.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicUInt32.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt32.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt32.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt32.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt32.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt32.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicUInt32 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: UInt32) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt32 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: UInt32, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt32>,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt32,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt32 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt32>,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt32,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt32 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return ptr.fetchSub(value, order: order)
    }
}

// MARK: - UInt64 -

extension Swift.UInt64: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt64
    public typealias AtomicPointer = AtomicUInt64Pointer
}

public final class AtomicUInt64 {
    public typealias Pointer = AtomicUInt64Pointer
    public typealias RawValue = CAtomicUInt64

    @usableFromInline var _storage: RawValue = 0

    @inlinable
    init() {}
}

extension AtomicUInt64 {
    @_transparent
    public convenience init(_ initialValue: RawValue) {
        self.init()
        AtomicUInt64.initialize(&_storage, to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        AtomicUInt64.store(&_storage, desired, order: order)
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
    public func exchange(_ desired: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.exchange(&_storage, desired, order: order)
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt64.compareExchange(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt64.compareExchange(
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
        _ expected: UnsafeMutablePointer<RawValue>,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicUInt64.compareExchangeWeak(
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
        _ expected: RawValue,
        _ desired: RawValue,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> RawValue {
        return AtomicUInt64.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }

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
    public func fetchAnd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.fetchAnd(&_storage, value, order: order)
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
    public func fetchOr(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.fetchOr(&_storage, value, order: order)
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
    public func fetchXor(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.fetchXor(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.fetchAdd(&_storage, value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: RawValue, order: AtomicMemoryOrder = .seqcst) -> RawValue {
        return AtomicUInt64.fetchSub(&_storage, value, order: order)
    }
}

extension AtomicUInt64 {
    @_transparent
    public static func initialize(_ ptr: Pointer, to initialValue: UInt64) {
        ptr.initialize(to: initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt64 {
        return ptr.load(order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: Pointer, _ desired: UInt64, order: AtomicStoreMemoryOrder = .seqcst) {
        ptr.store(desired, order: order)
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
    public static func exchange(_ ptr: Pointer, _ desired: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.exchange(desired, order: order)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt64>,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt64,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt64 {
        return ptr.compareExchange(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UnsafeMutablePointer<UInt64>,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
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
        _ ptr: Pointer,
        _ expected: UInt64,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt64 {
        return ptr.compareExchangeWeak(expected, desired, order: order, loadOrder: loadOrder)
    }

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
    public static func fetchAnd(_ ptr: Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.fetchAnd(value, order: order)
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
    public static func fetchOr(_ ptr: Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.fetchOr(value, order: order)
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
    public static func fetchXor(_ ptr: Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.fetchXor(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchAdd(_ ptr: Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.fetchAdd(value, order: order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public static func fetchSub(_ ptr: Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return ptr.fetchSub(value, order: order)
    }
}
