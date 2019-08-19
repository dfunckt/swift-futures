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
func _invokeDebugger() {
    raise(SIGTRAP)
}

extension Optional {
    @inlinable
    @discardableResult
    mutating func take() -> Wrapped? {
        var value: Wrapped?
        Swift.swap(&self, &value)
        return value
    }

    @inlinable
    func match<R>(some: (Wrapped) throws -> R, none: () throws -> R) rethrows -> R {
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
    var _isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    @inlinable
    var _isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }

    @inlinable
    func match<R>(success: (Success) throws -> R, failure: (Failure) throws -> R) rethrows -> R {
        switch self {
        case .success(let value):
            return try success(value)
        case .failure(let error):
            return try failure(error)
        }
    }
}

extension Result where Success: _ResultConvertible, Failure == Success.Failure {
    @inlinable
    func flatten() -> Result<Success.Success, Failure> {
        switch self {
        case .success(let value):
            return value._makeResult().match(
                success: { .success($0) },
                failure: { .failure($0) }
            )
        case .failure(let error):
            return .failure(error)
        }
    }
}

@usableFromInline
struct _StandardOutputStream: TextOutputStream {
    @inlinable
    init() {}

    @inlinable
    func write(_ string: String) {
        Swift.print(string, terminator: "")
    }
}

@usableFromInline
final class _Ref<T> {
    @usableFromInline var value: T

    @inlinable
    init(_ value: T) {
        self.value = value
    }
}

@inlinable
@inline(__always)
func _pointerAddressForDisplay<T: AnyObject>(_ obj: T) -> String {
    return Unmanaged.passUnretained(obj).toOpaque().debugDescription
}

@inlinable
@inline(__always)
func _pointerAddress<T: AnyObject>(_ obj: T) -> Int {
    return .init(bitPattern: ObjectIdentifier(obj))
}

@inlinable
@inline(__always)
func _isPowerOf2(_ n: Int) -> Bool {
    return UInt32(n).nonzeroBitCount == 1
}

/// Rounds the given integer up to the next power of two unless it is one
/// already. If `n` is 0, this function returns 1.
@inlinable
@inline(__always)
func _nextPowerOf2(_ n: Int) -> Int {
    if n == 0 {
        return 1
    }
    let u = UInt32(n)
    return Int(1 << (u.bitWidth - (u - 1).leadingZeroBitCount))
}
