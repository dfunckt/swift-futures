//
//  AtomicRef.swift
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

public typealias AtomicUSize = AtomicUInt

public final class AtomicRef<T: AnyObject> {
    public typealias Pointer = AtomicUSize.Pointer
    public typealias RawValue = AtomicUSize.RawValue

    @usableFromInline var _storage: AtomicUSize.RawValue = NIL

    @inlinable
    public init(_ obj: T? = nil) {
        AtomicRef.initialize(&_storage, to: obj)
    }

    @inlinable
    deinit {
        AtomicRef.store(&_storage, T?.none)
    }
}

extension AtomicRef {
    public var value: T? {
        @_transparent get { return load() }
        @_transparent set { store(newValue) }
    }

    @_transparent
    public func destroy(order: AtomicStoreMemoryOrder = .seqcst) {
        return AtomicRef.destroy(&_storage, order: order)
    }

    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> T? {
        return AtomicRef.load(&_storage, order: order)
    }

    @_transparent
    public func store(_ obj: T?, order: AtomicStoreMemoryOrder = .seqcst) {
        return AtomicRef.store(&_storage, obj, order: order)
    }

    @_transparent
    public func exchange(_ obj: T?, order: AtomicMemoryOrder = .seqcst) -> T? {
        return AtomicRef.exchange(&_storage, obj, order: order)
    }

    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<T?>,
        _ desired: T?,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        return AtomicRef.compareExchange(
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
        return AtomicRef.compareExchange(
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
        return AtomicRef.compareExchangeWeak(
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
        return AtomicRef.compareExchangeWeak(
            &_storage,
            expected,
            desired,
            order: order,
            loadOrder: loadOrder
        )
    }
}

// MARK: - Type Methods -

extension AtomicRef {
    @_transparent
    public static func initialize(_ ptr: Pointer, to obj: T? = nil) {
        let (bits, _) = _toOpaqueRetained(obj)
        Atomic.initialize(ptr, to: bits)
    }

    @_transparent
    public static func destroy(_ ref: Pointer, order: AtomicStoreMemoryOrder = .seqcst) {
        store(ref, nil, order: order)
    }

    @_transparent
    public static func load(_ ref: Pointer, order: AtomicLoadMemoryOrder = .seqcst) -> T? {
        let current = Atomic.load(ref, order: order)
        if current != NIL, let ptr = UnsafeRawPointer(bitPattern: current) {
            return Unmanaged.fromOpaque(ptr).takeUnretainedValue()
        }
        return nil
    }

    @_transparent
    public static func store(_ ref: Pointer, _ obj: T?, order: AtomicStoreMemoryOrder = .seqcst) {
        // swiftlint:disable:next force_unwrapping
        let order = AtomicMemoryOrder(rawValue: order.rawValue)!
        let desired = _toOpaqueRetained(obj)
        let current = Atomic.exchange(ref, desired.bits, order: order)
        if current != NIL, let ptr = UnsafeRawPointer(bitPattern: current) {
            Unmanaged<T>.fromOpaque(ptr).release()
        }
    }

    @_transparent
    public static func exchange(_ ref: Pointer, _ obj: T?, order: AtomicMemoryOrder = .seqcst) -> T? {
        let desired = _toOpaqueRetained(obj)
        let current = Atomic.exchange(ref, desired.bits, order: order)
        if current != NIL, let ptr = UnsafeRawPointer(bitPattern: current) {
            return Unmanaged.fromOpaque(ptr).takeRetainedValue()
        }
        return nil
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
        if Atomic.compareExchange(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            withExtendedLifetime(desired) {}
            return true
        }
        if exp.bits != NIL, let ptr = UnsafeRawPointer(bitPattern: exp.bits) {
            expected.pointee = Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
        } else {
            expected.pointee = nil
        }
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
        if Atomic.compareExchange(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            withExtendedLifetime(desired) {}
            return expected
        }
        if exp.bits != NIL, let ptr = UnsafeRawPointer(bitPattern: exp.bits) {
            return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
        }
        return nil
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
        if Atomic.compareExchangeWeak(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            withExtendedLifetime(desired) {}
            return true
        }
        if exp.bits != NIL, let ptr = UnsafeRawPointer(bitPattern: exp.bits) {
            expected.pointee = Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
        } else {
            expected.pointee = nil
        }
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
        if Atomic.compareExchangeWeak(
            ref,
            &exp.bits,
            des.bits,
            order: order,
            loadOrder: loadOrder ?? order.strongestLoadOrder()
        ) {
            _ = des.ptr?.retain()
            exp.ptr?.release()
            withExtendedLifetime(desired) {}
            return expected
        }
        if exp.bits != NIL, let ptr = UnsafeRawPointer(bitPattern: exp.bits) {
            return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
        }
        return nil
    }
}
