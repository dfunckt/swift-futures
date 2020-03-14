//
//  Private.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)
import Darwin.POSIX.signal
#else
import Glibc
#endif

@usableFromInline
@inline(never)
internal func invokeDebugger() {
    raise(SIGTRAP)
}

extension Optional {
    @inlinable
    @_transparent
    @discardableResult
    internal mutating func move() -> Wrapped? {
        var value: Wrapped?
        Swift.swap(&self, &value)
        return value
    }

    @inlinable
    @_transparent
    internal func match<R>(some: (Wrapped) throws -> R, none: () throws -> R) rethrows -> R {
        switch self {
        case .some(let value):
            return try some(value)
        case .none:
            return try none()
        }
    }
}

extension Result {
    @inlinable
    internal var _isSuccess: Bool {
        @_transparent get {
            switch self {
            case .success:
                return true
            case .failure:
                return false
            }
        }
    }

    @inlinable
    internal var _isFailure: Bool {
        @_transparent get {
            switch self {
            case .success:
                return false
            case .failure:
                return true
            }
        }
    }

    @inlinable
    @_transparent
    internal func match<R>(success: (Success) throws -> R, failure: (Failure) throws -> R) rethrows -> R {
        switch self {
        case .success(let value):
            return try success(value)
        case .failure(let error):
            return try failure(error)
        }
    }

    @inlinable
    @_transparent
    internal func flatten<NewSuccess>() -> Result<NewSuccess, Failure> where Success == Result<NewSuccess, Failure> {
        switch self {
        case .success(let result):
            return result.match(
                success: { .success($0) },
                failure: { .failure($0) }
            )
        case .failure(let error):
            return .failure(error)
        }
    }
}

@usableFromInline
internal struct StandardOutputStream: TextOutputStream {
    @inlinable
    internal init() {}

    @inlinable
    internal func write(_ string: String) {
        Swift.print(string, terminator: "")
    }
}

@usableFromInline
internal final class Box<T> {
    @usableFromInline internal var value: T

    @inlinable
    internal init(_ value: T) {
        self.value = value
    }
}

@usableFromInline
internal struct WeakReference<T: AnyObject> {
    @usableFromInline internal weak var value: T?

    @inlinable
    internal init(_ value: T) {
        self.value = value
    }
}

@inlinable
@_transparent
internal func pointerAddress<T: AnyObject>(_ obj: T) -> Int {
    return .init(bitPattern: ObjectIdentifier(obj))
}

@inlinable
@_transparent
internal func pointerAddressForDisplay<T: AnyObject>(_ obj: T) -> String {
    return Unmanaged.passUnretained(obj).toOpaque().debugDescription
}

@inlinable
@_transparent
internal func isPowerOf2(_ n: Int) -> Bool {
    return UInt32(n).nonzeroBitCount == 1
}

/// Rounds the given integer up to the next power of two unless it is one
/// already. If `n` is 0, this function returns 1.
@inlinable
@_transparent
internal func nextPowerOf2(_ n: Int) -> Int {
    if n == 0 {
        return 1
    }
    let u = UInt32(n)
    return Int(1 << (u.bitWidth - (u - 1).leadingZeroBitCount))
}
