//
//  AtomicEnum.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

@inlinable
@_transparent
func _fromRawValue<R: RawRepresentable>(_ rawValue: R.RawValue) -> R {
    // swiftlint:disable:next force_unwrapping
    return R(rawValue: rawValue)!
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

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == Int, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == Int {
    @_transparent
    public static func initialize(_ ref: AtomicIntPointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicIntPointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicIntPointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == Int {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - Int8 -

extension AtomicEnum where R.RawValue == Int8 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == Int8, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == Int8 {
    @_transparent
    public static func initialize(_ ref: AtomicInt8Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicInt8Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicInt8Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == Int8 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - Int16 -

extension AtomicEnum where R.RawValue == Int16 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == Int16, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == Int16 {
    @_transparent
    public static func initialize(_ ref: AtomicInt16Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicInt16Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicInt16Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == Int16 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - Int32 -

extension AtomicEnum where R.RawValue == Int32 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == Int32, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == Int32 {
    @_transparent
    public static func initialize(_ ref: AtomicInt32Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicInt32Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicInt32Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == Int32 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - Int64 -

extension AtomicEnum where R.RawValue == Int64 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == Int64, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == Int64 {
    @_transparent
    public static func initialize(_ ref: AtomicInt64Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicInt64Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicInt64Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == Int64 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - UInt -

extension AtomicEnum where R.RawValue == UInt {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == UInt, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == UInt {
    @_transparent
    public static func initialize(_ ref: AtomicUIntPointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicUIntPointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicUIntPointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicUIntPointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUIntPointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUIntPointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == UInt {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicUIntPointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - UInt8 -

extension AtomicEnum where R.RawValue == UInt8 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == UInt8, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == UInt8 {
    @_transparent
    public static func initialize(_ ref: AtomicUInt8Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicUInt8Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicUInt8Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicUInt8Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt8Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt8Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == UInt8 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicUInt8Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - UInt16 -

extension AtomicEnum where R.RawValue == UInt16 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == UInt16, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == UInt16 {
    @_transparent
    public static func initialize(_ ref: AtomicUInt16Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicUInt16Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicUInt16Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicUInt16Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt16Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt16Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == UInt16 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicUInt16Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - UInt32 -

extension AtomicEnum where R.RawValue == UInt32 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == UInt32, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == UInt32 {
    @_transparent
    public static func initialize(_ ref: AtomicUInt32Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicUInt32Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicUInt32Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicUInt32Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt32Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt32Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == UInt32 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicUInt32Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}

// MARK: - UInt64 -

extension AtomicEnum where R.RawValue == UInt64 {
    @_transparent
    public convenience init(_ initialValue: R) {
        self.init()
        R.initialize(&_storage, to: initialValue)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> R {
        return R.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ value: R, order: AtomicStoreMemoryOrder = .seqcst) {
        return R.store(&_storage, value, order: order)
    }

    @_transparent
    public func exchange(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.exchange(&_storage, value, order: order)
    }

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

// MARK: -

extension AtomicEnum where R.RawValue == UInt64, R: OptionSet {
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchAnd(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchOr(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchOr(&_storage, value, order: order)
    }

    @_transparent
    @discardableResult
    public func fetchXor(_ value: R, order: AtomicMemoryOrder = .seqcst) -> R {
        return R.fetchXor(&_storage, value, order: order)
    }
}

// MARK: -

extension RawRepresentable where RawValue == UInt64 {
    @_transparent
    public static func initialize(_ ref: AtomicUInt64Pointer, to initialValue: Self) {
        Atomic.initialize(ref, to: _toRawValue(initialValue))
    }

    @_transparent
    public static func load(_ ref: AtomicUInt64Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.load(ref, order: order))
    }

    @_transparent
    public static func store(_ ref: AtomicUInt64Pointer, _ desired: Self, order: AtomicStoreMemoryOrder = .seqcst) {
        Atomic.store(ref, _toRawValue(desired), order: order)
    }

    @_transparent
    public static func exchange(_ ref: AtomicUInt64Pointer, _ desired: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.exchange(ref, _toRawValue(desired), order: order))
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: AtomicUInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchange(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt64Pointer,
        _ expected: UnsafeMutablePointer<Self>,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var primitive = _toRawValue(expected.pointee)
        let result = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        expected.pointee = _fromRawValue(primitive)
        return result
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: AtomicUInt64Pointer,
        _ expected: Self,
        _ desired: Self,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Self {
        var primitive = _toRawValue(expected)
        _ = Atomic.compareExchangeWeak(
            ref,
            &primitive,
            _toRawValue(desired),
            order: order,
            loadOrder: loadOrder
        )
        return _fromRawValue(primitive)
    }
}

// MARK: -

extension OptionSet where RawValue == UInt64 {
    @_transparent
    @discardableResult
    public static func fetchAnd(_ ref: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchAnd(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchOr(_ ref: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchOr(ref, _toRawValue(value), order: order))
    }

    @_transparent
    @discardableResult
    public static func fetchXor(_ ref: AtomicUInt64Pointer, _ value: Self, order: AtomicMemoryOrder = .seqcst) -> Self {
        return _fromRawValue(Atomic.fetchXor(ref, _toRawValue(value), order: order))
    }
}
