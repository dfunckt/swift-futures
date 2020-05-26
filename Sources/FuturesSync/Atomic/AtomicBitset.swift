//
//  AtomicBitset.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

public protocol AtomicBitset: ExpressibleByIntegerLiteral, Equatable {
    associatedtype RawValue: FixedWidthInteger & UnsignedInteger

    var rawValue: RawValue { get }

    init(rawValue: RawValue)

    static var bitWidth: Int { get }
}

extension AtomicBitset where RawValue == IntegerLiteralType {
    @_transparent
    public init(integerLiteral value: Self.IntegerLiteralType) {
        self = .init(rawValue: value)
    }
}

extension AtomicBitset {
    @inlinable
    public static var bitWidth: Int {
        @_transparent get { RawValue.bitWidth }
    }
}

extension AtomicBitset where Self: CustomDebugStringConvertible {
    @inlinable
    public var debugDescription: String {
        let bin = String(rawValue, radix: 2)
        let len = Self.bitWidth - bin.count
        let pad = String(repeating: "0", count: len > 0 ? len : 0)
        return "0b\(pad)\(bin)"
    }
}

extension AtomicBitset {
    @inlinable
    public static var empty: Self {
        @_transparent get { .init(rawValue: 0) }
    }

    @_transparent
    public func contains(_ other: Self) -> Bool {
        rawValue & other.rawValue > 0
    }

    @_transparent
    public func containsAll(_ other: Self) -> Bool {
        rawValue & other.rawValue == other.rawValue
    }

    @_transparent
    public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    @_transparent
    public static func | (_ lhs: Self, _ rhs: Self) -> Self {
        return .init(rawValue: lhs.rawValue | rhs.rawValue)
    }

    @_transparent
    public static func & (_ lhs: Self, _ rhs: Self) -> Self {
        return .init(rawValue: lhs.rawValue & rhs.rawValue)
    }

    @_transparent
    public static func ^ (_ lhs: Self, _ rhs: Self) -> Self {
        return .init(rawValue: lhs.rawValue ^ rhs.rawValue)
    }

    @_transparent
    public static prefix func ~ (_ x: Self) -> Self {
        return .init(rawValue: ~x.rawValue)
    }
}

// MARK: -

@inlinable
@_transparent
func _fromRawValue<B: AtomicBitset>(_ rawValue: B.RawValue, _: B.Type = B.self) -> B {
    return B(rawValue: rawValue)
}

@inlinable
@_transparent
func _toRawValue<B: AtomicBitset>(_ bitset: B) -> B.RawValue {
    return bitset.rawValue
}

// MARK: - UInt -

extension AtomicBitset where RawValue == UInt {
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
    public static func fetchAdd(_ ptr: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAdd(_toRawValue(value), order: order))
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
    public static func fetchSub(_ ptr: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchSub(_toRawValue(value), order: order))
    }
}

// MARK: - UInt8 -

extension AtomicBitset where RawValue == UInt8 {
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
    public static func fetchAdd(_ ptr: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAdd(_toRawValue(value), order: order))
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
    public static func fetchSub(_ ptr: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchSub(_toRawValue(value), order: order))
    }
}

// MARK: - UInt16 -

extension AtomicBitset where RawValue == UInt16 {
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
    public static func fetchAdd(_ ptr: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAdd(_toRawValue(value), order: order))
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
    public static func fetchSub(_ ptr: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchSub(_toRawValue(value), order: order))
    }
}

// MARK: - UInt32 -

extension AtomicBitset where RawValue == UInt32 {
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
    public static func fetchAdd(_ ptr: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAdd(_toRawValue(value), order: order))
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
    public static func fetchSub(_ ptr: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchSub(_toRawValue(value), order: order))
    }
}

// MARK: - UInt64 -

extension AtomicBitset where RawValue == UInt64 {
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
    public static func fetchAdd(_ ptr: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchAdd(_toRawValue(value), order: order))
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
    public static func fetchSub(_ ptr: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(ptr.fetchSub(_toRawValue(value), order: order))
    }
}
