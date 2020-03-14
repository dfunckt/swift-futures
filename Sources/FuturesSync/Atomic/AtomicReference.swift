//
//  AtomicReference.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@usableFromInline let NIL: UInt = 0xDEADBEE

@inlinable
@_transparent
func _toOpaque<T: AnyObject>(_ obj: T?) -> (bits: UInt, ptr: Unmanaged<T>?) {
    if let ref = obj {
        let ptr = Unmanaged.passUnretained(ref)
        return (UInt(bitPattern: ptr.toOpaque()), ptr)
    }
    return (NIL, nil)
}

@inlinable
@_transparent
func _toOpaqueRetained<T: AnyObject>(_ obj: T?) -> (bits: UInt, ptr: Unmanaged<T>?) {
    if let ref = obj {
        let ptr = Unmanaged.passRetained(ref)
        return (UInt(bitPattern: ptr.toOpaque()), ptr)
    }
    return (NIL, nil)
}

@inlinable
@_transparent
func _fromOpaque<T: AnyObject>(_ bits: UInt, as _: T.Type = T.self) -> Unmanaged<T>? {
    if bits != NIL, let ptr = UnsafeRawPointer(bitPattern: bits) {
        return Unmanaged.fromOpaque(ptr)
    }
    return nil
}

public typealias AtomicUSize = AtomicUInt

public final class AtomicReference<T: AnyObject> {
    public typealias Pointer = AtomicUSize.Pointer
    public typealias RawValue = AtomicUSize.RawValue

    @usableFromInline var _storage: AtomicUSize.RawValue = NIL

    @inlinable
    public init(_ obj: T? = nil) {
        AtomicReference.initialize(&_storage, to: obj)
    }

    @inlinable
    deinit {
        AtomicReference.destroy(&_storage)
    }
}

extension AtomicReference {
    public var value: T? {
        @_transparent get { load() }
        @_transparent set { store(newValue) }
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> T? {
        return AtomicReference.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ obj: T?, order: AtomicStoreMemoryOrder = .seqcst) {
        return AtomicReference.store(&_storage, obj, order: order)
    }

    @_transparent
    public func exchange(_ obj: T?, order: AtomicMemoryOrder = .seqcst) -> T? {
        return AtomicReference.exchange(&_storage, obj, order: order)
    }

    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<T?>,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicReference.compareExchange(
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
        _ expected: T?,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> T? {
        return AtomicReference.compareExchange(
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
        _ expected: UnsafeMutablePointer<T?>,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicReference.compareExchangeWeak(
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
        _ expected: T?,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> T? {
        return AtomicReference.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

extension AtomicReference {
    @_transparent
    public static func initialize(_ ptr: Pointer, to obj: T? = nil) {
        let (bits, _) = _toOpaqueRetained(obj)
        AtomicUSize.initialize(ptr, to: bits)
    }

    @_transparent
    public static func destroy(_ ref: Pointer, order: AtomicStoreMemoryOrder = .seqcst) {
        store(ref, nil, order: order)
    }

    @_transparent
    public static func load(_ ref: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> T? {
        let current = AtomicUSize.load(ref, order: order)
        return _fromOpaque(current)?.takeUnretainedValue()
    }

    @_transparent
    public static func store(_ ref: Pointer, _ obj: T?, order: AtomicStoreMemoryOrder = .seqcst) {
        // swiftlint:disable:next force_unwrapping
        let order = AtomicMemoryOrder(rawValue: order.rawValue)!
        let desired = _toOpaqueRetained(obj)
        let current = AtomicUSize.exchange(ref, desired.bits, order: order)
        _fromOpaque(current, as: T.self)?.release()
    }

    @_transparent
    public static func exchange(_ ref: Pointer, _ obj: T?, order: AtomicMemoryOrder = .seqcst) -> T? {
        let desired = _toOpaqueRetained(obj)
        let current = AtomicUSize.exchange(ref, desired.bits, order: order)
        return _fromOpaque(current)?.takeRetainedValue()
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: Pointer,
        _ expected: UnsafeMutablePointer<T?>,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var exp = _toOpaque(expected.pointee)
        let des = _toOpaque(desired)
        if AtomicUSize.compareExchange(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            return withExtendedLifetime(desired) {
                true
            }
        }
        expected.pointee = _fromOpaque(exp.bits)?.takeUnretainedValue()
        return false
    }

    @_transparent
    @discardableResult
    public static func compareExchange(
        _ ref: Pointer,
        _ expected: T?,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> T? {
        var exp = _toOpaque(expected)
        let des = _toOpaque(desired)
        if AtomicUSize.compareExchange(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            return withExtendedLifetime(desired) {
                expected
            }
        }
        return _fromOpaque(exp.bits)?.takeUnretainedValue()
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: Pointer,
        _ expected: UnsafeMutablePointer<T?>,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        var exp = _toOpaque(expected.pointee)
        let des = _toOpaque(desired)
        if AtomicUSize.compareExchangeWeak(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            return withExtendedLifetime(desired) {
                true
            }
        }
        expected.pointee = _fromOpaque(exp.bits)?.takeUnretainedValue()
        return false
    }

    @_transparent
    @discardableResult
    public static func compareExchangeWeak(
        _ ref: Pointer,
        _ expected: T?,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> T? {
        var exp = _toOpaque(expected)
        let des = _toOpaque(desired)
        if AtomicUSize.compareExchangeWeak(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            return withExtendedLifetime(desired) {
                expected
            }
        }
        return _fromOpaque(exp.bits)?.takeUnretainedValue()
    }
}
