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

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicBoolPointer, to initialValue: Bool) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicBoolPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Bool {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicBoolPointer, _ desired: Bool, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicBoolPointer, _ desired: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return CAtomicExchange(ptr, desired, order)
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
        _ ptr: AtomicBoolPointer,
        _ expected: UnsafeMutablePointer<Bool>,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicBoolPointer,
        _ expected: Bool,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ ptr: AtomicBoolPointer,
        _ expected: UnsafeMutablePointer<Bool>,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicBoolPointer,
        _ expected: Bool,
        _ desired: Bool,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicBoolPointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicBoolPointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicBoolPointer, _ value: Bool, order: AtomicMemoryOrder = .seqcst) -> Bool {
        return CAtomicFetchXor(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
    }
}

// MARK: - Int -

extension Swift.Int: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt
    public typealias AtomicPointer = AtomicIntPointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicIntPointer, to initialValue: Int) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicIntPointer, _ desired: Int, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicIntPointer, _ desired: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<Int>,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicIntPointer,
        _ expected: Int,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<Int>,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicIntPointer,
        _ expected: Int,
        _ desired: Int,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicIntPointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicIntPointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicIntPointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicIntPointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicIntPointer, _ value: Int, order: AtomicMemoryOrder = .seqcst) -> Int {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - Int8 -

extension Swift.Int8: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt8
    public typealias AtomicPointer = AtomicInt8Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicInt8Pointer, to initialValue: Int8) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int8 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt8Pointer, _ desired: Int8, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicInt8Pointer, _ desired: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<Int8>,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicInt8Pointer,
        _ expected: Int8,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int8 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<Int8>,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicInt8Pointer,
        _ expected: Int8,
        _ desired: Int8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int8 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicInt8Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicInt8Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicInt8Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicInt8Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicInt8Pointer, _ value: Int8, order: AtomicMemoryOrder = .seqcst) -> Int8 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - Int16 -

extension Swift.Int16: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt16
    public typealias AtomicPointer = AtomicInt16Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicInt16Pointer, to initialValue: Int16) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int16 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt16Pointer, _ desired: Int16, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicInt16Pointer, _ desired: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<Int16>,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicInt16Pointer,
        _ expected: Int16,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int16 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<Int16>,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicInt16Pointer,
        _ expected: Int16,
        _ desired: Int16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int16 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicInt16Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicInt16Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicInt16Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicInt16Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicInt16Pointer, _ value: Int16, order: AtomicMemoryOrder = .seqcst) -> Int16 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - Int32 -

extension Swift.Int32: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt32
    public typealias AtomicPointer = AtomicInt32Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicInt32Pointer, to initialValue: Int32) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int32 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt32Pointer, _ desired: Int32, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicInt32Pointer, _ desired: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<Int32>,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicInt32Pointer,
        _ expected: Int32,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int32 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<Int32>,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicInt32Pointer,
        _ expected: Int32,
        _ desired: Int32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int32 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicInt32Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicInt32Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicInt32Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicInt32Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicInt32Pointer, _ value: Int32, order: AtomicMemoryOrder = .seqcst) -> Int32 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - Int64 -

extension Swift.Int64: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicInt64
    public typealias AtomicPointer = AtomicInt64Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicInt64Pointer, to initialValue: Int64) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Int64 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicInt64Pointer, _ desired: Int64, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicInt64Pointer, _ desired: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<Int64>,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicInt64Pointer,
        _ expected: Int64,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int64 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<Int64>,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicInt64Pointer,
        _ expected: Int64,
        _ desired: Int64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Int64 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicInt64Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicInt64Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicInt64Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicInt64Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicInt64Pointer, _ value: Int64, order: AtomicMemoryOrder = .seqcst) -> Int64 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - UInt -

extension Swift.UInt: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt
    public typealias AtomicPointer = AtomicUIntPointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicUIntPointer, to initialValue: UInt) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUIntPointer, _ desired: UInt, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicUIntPointer, _ desired: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<UInt>,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicUIntPointer,
        _ expected: UInt,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<UInt>,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicUIntPointer,
        _ expected: UInt,
        _ desired: UInt,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicUIntPointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicUIntPointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicUIntPointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicUIntPointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicUIntPointer, _ value: UInt, order: AtomicMemoryOrder = .seqcst) -> UInt {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - UInt8 -

extension Swift.UInt8: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt8
    public typealias AtomicPointer = AtomicUInt8Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt8Pointer, to initialValue: UInt8) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt8Pointer, _ desired: UInt8, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicUInt8Pointer, _ desired: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<UInt8>,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicUInt8Pointer,
        _ expected: UInt8,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt8 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<UInt8>,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt8Pointer,
        _ expected: UInt8,
        _ desired: UInt8,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt8 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicUInt8Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicUInt8Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicUInt8Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicUInt8Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicUInt8Pointer, _ value: UInt8, order: AtomicMemoryOrder = .seqcst) -> UInt8 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - UInt16 -

extension Swift.UInt16: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt16
    public typealias AtomicPointer = AtomicUInt16Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt16Pointer, to initialValue: UInt16) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt16Pointer, _ desired: UInt16, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicUInt16Pointer, _ desired: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<UInt16>,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicUInt16Pointer,
        _ expected: UInt16,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt16 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<UInt16>,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt16Pointer,
        _ expected: UInt16,
        _ desired: UInt16,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt16 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicUInt16Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicUInt16Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicUInt16Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicUInt16Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicUInt16Pointer, _ value: UInt16, order: AtomicMemoryOrder = .seqcst) -> UInt16 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - UInt32 -

extension Swift.UInt32: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt32
    public typealias AtomicPointer = AtomicUInt32Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt32Pointer, to initialValue: UInt32) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt32Pointer, _ desired: UInt32, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicUInt32Pointer, _ desired: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<UInt32>,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicUInt32Pointer,
        _ expected: UInt32,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt32 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<UInt32>,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt32Pointer,
        _ expected: UInt32,
        _ desired: UInt32,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt32 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicUInt32Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicUInt32Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicUInt32Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicUInt32Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicUInt32Pointer, _ value: UInt32, order: AtomicMemoryOrder = .seqcst) -> UInt32 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}

// MARK: - UInt64 -

extension Swift.UInt64: _CAtomicInteger {
    public typealias AtomicRawValue = CAtomicUInt64
    public typealias AtomicPointer = AtomicUInt64Pointer
}

extension Atomic {
    @_transparent
    public static func initialize(_ ptr: AtomicUInt64Pointer, to initialValue: UInt64) {
        CAtomicInitialize(ptr, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public static func load(_ ptr: AtomicUInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicLoad(ptr, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public static func store(_ ptr: AtomicUInt64Pointer, _ desired: UInt64, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicStore(ptr, desired, order)
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
    public static func exchange(_ ptr: AtomicUInt64Pointer, _ desired: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicExchange(ptr, desired, order)
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
        _ expected: UnsafeMutablePointer<UInt64>,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeStrong(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchange(
        _ ptr: AtomicUInt64Pointer,
        _ expected: UInt64,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt64 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeStrong(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
        _ expected: UnsafeMutablePointer<UInt64>,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicCompareExchangeWeak(
            ptr, expected, desired, order, loadOrder
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
    public static func compareExchangeWeak(
        _ ptr: AtomicUInt64Pointer,
        _ expected: UInt64,
        _ desired: UInt64,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> UInt64 {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicCompareExchangeWeak(
            ptr, &current, desired, order, loadOrder
        )
        return current
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
    public static func fetchAnd(_ ptr: AtomicUInt64Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicFetchAnd(ptr, value, order)
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
    public static func fetchOr(_ ptr: AtomicUInt64Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicFetchOr(ptr, value, order)
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
    public static func fetchXor(_ ptr: AtomicUInt64Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicFetchXor(ptr, value, order)
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
    public static func fetchAdd(_ ptr: AtomicUInt64Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicFetchAdd(ptr, value, order)
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
    public static func fetchSub(_ ptr: AtomicUInt64Pointer, _ value: UInt64, order: AtomicMemoryOrder = .seqcst) -> UInt64 {
        return CAtomicFetchSub(ptr, value, order)
    }
}

// MARK: -

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
        Atomic.initialize(&_storage, to: initialValue)
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
        return Atomic.load(&_storage, order: order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: RawValue, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(&_storage, desired, order: order)
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
        return Atomic.exchange(&_storage, desired, order: order)
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchange(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.compareExchangeWeak(
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
        return Atomic.fetchAnd(&_storage, value, order: order)
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
        return Atomic.fetchOr(&_storage, value, order: order)
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
        return Atomic.fetchXor(&_storage, value, order: order)
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
        return Atomic.fetchAdd(&_storage, value, order: order)
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
        return Atomic.fetchSub(&_storage, value, order: order)
    }
}
