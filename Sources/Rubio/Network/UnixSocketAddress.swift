//
//  UnixSocketAddress.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

@usableFromInline let _sun_size = MemoryLayout<sockaddr_un>.size
@usableFromInline let _sun_path_offset = MemoryLayout.offset(of: \sockaddr_un.sun_path)!
@usableFromInline let _sun_path_size = MemoryLayout.size(ofValue: sockaddr_un().sun_path)

@inlinable
func _makeSocketAddress(
    pathBytes: UnsafeRawBufferPointer,
    forceAbstract: Bool = false
) -> (sockaddr_un, socklen_t)? {
    // `pathBytes` must be at most (sun_path.count - 1) in length
    // to allow space for the NUL byte we're going to add to
    // terminate the path name or denote an abstract address.
    if pathBytes.count >= _sun_path_size {
        return nil
    }

    var addr = sockaddr_un()
    addr.sun_family = .init(AF_UNIX)

    if pathBytes.count == 0 {
        // unnamed socket
        if forceAbstract {
            // we were explicitly asked for an abstract address,
            // so we really need at least one byte of data
            return nil
        }
        return (addr, .init(_sun_path_offset))
    }

    let offset = pathBytes[0] == 0 ? 1 : 0 // strip NUL prefix
    let forceAbstract = forceAbstract || offset == 1

    // pathname must *not* contain NUL-bytes
    if !forceAbstract, pathBytes.contains(0) {
        return nil
    }

    // copy the buffer into addr.sun_path
    withUnsafeMutableBytes(of: &addr.sun_path) { buf in
        if forceAbstract {
            buf.baseAddress!.advanced(by: 1).copyMemory(
                from: pathBytes.baseAddress!.advanced(by: offset),
                byteCount: pathBytes.count
            )
        } else {
            buf.copyMemory(from: pathBytes)
        }
    }

    // We added a NUL-byte either at the start of `path` (if
    // `forceAbstract` is `true`), or at the end (if this is
    // a pathname socket), so add 1 to total length.
    return (addr, .init(_sun_path_offset + 1 + pathBytes.count))
}

public struct UnixSocketAddress {
    public let rawValue: sockaddr_un
    public let length: socklen_t // is always >= sun_path_offset

    @inlinable
    public init(_ rawValue: sockaddr_un, length: socklen_t) {
        self.rawValue = rawValue
        self.length = length == 0 ? .init(_sun_path_offset) : length
    }
}

extension UnixSocketAddress {
    /// Creates an unnamed socket address.
    ///
    /// A socket that has not been bound to a pathname using bind(2) has no
    /// name. Likewise, the two sockets created by `Socket.makePair()` are
    /// unnamed.
    @inlinable
    public init() {
        var addr = sockaddr_un()
        addr.sun_family = .init(AF_UNIX)
        self.init(addr, length: .init(_sun_path_offset))
    }

    /// Creates an abstract socket address.
    ///
    /// An abstract socket address is distinguished from a pathname socket
    /// by the fact that `sun_path[0]` is a null byte (`\0`). The socket's
    /// address in this namespace is given by the additional bytes in `sun_path`
    /// that are covered by the specified length of the address structure.
    /// Null bytes in the name have no special significance. The name has no
    /// connection with filesystem pathnames.
    ///
    /// This initializer automatically prepends the null byte.
    ///
    /// Abstract sockets automatically disappear when all open references to
    /// the socket are closed.
    ///
    /// The abstract socket namespace is a non-portable Linux extension.
    @inlinable
    public init?(abstract name: String) {
        var name = name
        let result = name.withUTF8 {
            _makeSocketAddress(pathBytes: .init($0), forceAbstract: true)
        }
        guard let (addr, length) = result else {
            return nil
        }
        self.init(addr, length: length)
    }

    @inlinable
    public init?(path: String) {
        var path = path
        let result = path.withUTF8 {
            _makeSocketAddress(pathBytes: .init($0), forceAbstract: false)
        }
        guard let (addr, length) = result else {
            return nil
        }
        self.init(addr, length: length)
    }
}

extension UnixSocketAddress {
    public var addressFamily: CInt {
        @_transparent get { AF_UNIX }
    }

    public var protocolFamily: CInt {
        @_transparent get { PF_UNIX }
    }
}

extension UnixSocketAddress {
    public enum Kind {
        case unnamed
        case abstract(String)
        case pathname(String)
    }

    @inlinable
    public var kind: Kind {
        let pathLength = Int(length) - _sun_path_offset

        if pathLength == 0 {
            return .unnamed
        }

        return withUnsafePointer(to: rawValue.sun_path) {
            $0.withMemoryRebound(to: CChar.self, capacity: pathLength) { path in
                if path[0] == 0 {
                    return .abstract(.init(
                        decoding: UnsafeRawBufferPointer(
                            start: path.advanced(by: 1), // skip first NUL-byte
                            count: pathLength - 1
                        ),
                        as: Unicode.UTF8.self
                    ))
                }
                return .pathname(.init(cString: path))
            }
        }
    }
}

extension UnixSocketAddress: SocketAddressProtocol {
    @inlinable
    public init?(_ storage: SocketAddressStorage) {
        guard storage.addressFamily == sa_family_t(AF_UNIX) else {
            return nil
        }
        self.init(storage.unsafeBitcast(as: sockaddr_un.self), length: storage.length)
    }

    @_transparent
    public func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T {
        return try withUnsafePointer(to: rawValue) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, socklen_t(length))
            }
        }
    }
}

extension UnixSocketAddress: Equatable {
    @_transparent
    public static func == (lhs: UnixSocketAddress, rhs: UnixSocketAddress) -> Bool {
        let length = lhs.length
        if length != rhs.length {
            return false
        }
        return withUnsafePointer(to: lhs.rawValue.sun_path) { l in
            withUnsafePointer(to: rhs.rawValue.sun_path) { r in
                memcmp(l, r, .init(length)) == 0
            }
        }
    }
}

extension UnixSocketAddress: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(length)
        withUnsafePointer(to: rawValue.sun_path) {
            hasher.combine(bytes: .init(start: $0, count: .init(length)))
        }
    }
}

extension UnixSocketAddress: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            switch kind {
            case .unnamed:
                return "(unnamed)"
            case .abstract(let name):
                return name
            case .pathname(let path):
                return path
            }
        }
    }
}

extension UnixSocketAddress: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        if description == "(unnamed)" || description == "" {
            self.init()
            return
        }
        var path = description
        let result = path.withUTF8 {
            _makeSocketAddress(pathBytes: .init($0), forceAbstract: false)
        }
        guard let (addr, length) = result else {
            return nil
        }
        self.init(addr, length: length)
    }
}
