//
//  SocketAddress.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

public protocol SocketAddressProtocol {
    func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T
}

public struct SocketAddressStorage {
    @usableFromInline var _storage: sockaddr_storage
    @usableFromInline var _length: socklen_t

    @inlinable
    public init(storage: sockaddr_storage, length: socklen_t) {
        _storage = storage
        _length = length
    }
}

extension SocketAddressStorage {
    public var addressFamily: sa_family_t {
        @_transparent get { _storage.ss_family }
    }

    public var length: socklen_t {
        @_transparent get { _length }
    }

    @_transparent
    public func unsafeBitcast<S>(as _: S.Type) -> S {
        withUnsafeBytes(of: _storage) {
            $0.load(as: S.self)
        }
    }
}

extension SocketAddressStorage {
    @inlinable
    public init() {
        _storage = .init()
        _length = .init(MemoryLayout.size(ofValue: _storage))
    }

    @_transparent
    public mutating func withUnsafeMutablePointerToRawValue<T>(
        _ body: (UnsafeMutablePointer<sockaddr>, UnsafeMutablePointer<socklen_t>) throws -> T
    ) rethrows -> T {
        return try withUnsafeMutablePointer(to: &_storage) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, &_length)
            }
        }
    }
}

extension SocketAddressStorage: SocketAddressProtocol {
    @_transparent
    public func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T {
        return try withUnsafePointer(to: _storage) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, length)
            }
        }
    }
}
