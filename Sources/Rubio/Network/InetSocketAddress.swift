//
//  InetSocketAddress.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

//              InetSocketAddress
//            __________|__________
//           /                     \
//  IPv4SocketAddress       IPv6SocketAddress
//          |                      |
//     IPv4Address            IPv6Address

public enum InetSocketAddress {
    case v4(IPv4SocketAddress)
    case v6(IPv6SocketAddress)
}

extension InetSocketAddress {
    public var addressFamily: CInt {
        @_transparent get {
            switch self {
            case .v4:
                return AF_INET
            case .v6:
                return AF_INET6
            }
        }
    }

    public var protocolFamily: CInt {
        @_transparent get {
            switch self {
            case .v4:
                return PF_INET
            case .v6:
                return PF_INET6
            }
        }
    }

    public var ipAddress: InetAddress {
        @_transparent get {
            switch self {
            case .v4(let addr):
                return .v4(addr.ipAddress)
            case .v6(let addr):
                return .v6(addr.ipAddress)
            }
        }
    }

    public var port: UInt16 {
        @_transparent get {
            switch self {
            case .v4(let addr):
                return addr.port
            case .v6(let addr):
                return addr.port
            }
        }
    }
}

extension InetSocketAddress {
    @inlinable
    public init(_ address: IPv4SocketAddress) {
        self = .v4(address)
    }

    @inlinable
    public init(_ address: IPv6SocketAddress) {
        self = .v6(address)
    }

    @_transparent
    public init(ipv4: IPv4Address, port: UInt16) {
        self.init(IPv4SocketAddress(ip: ipv4, port: port))
    }

    @_transparent
    public init(ipv6: IPv6Address, port: UInt16) {
        self.init(IPv6SocketAddress(ip: ipv6, port: port))
    }

    @_transparent
    public init(ip: InetAddress, port: UInt16) {
        switch ip {
        case .v4(let address):
            self.init(IPv4SocketAddress(ip: address, port: port))
        case .v6(let address):
            self.init(IPv6SocketAddress(ip: address, port: port))
        }
    }

    @_transparent
    public init(_ ip: StaticString, port: UInt16 = 0) {
        switch InetAddress(ip) {
        case .v4(let address):
            self.init(IPv4SocketAddress(ip: address, port: port))
        case .v6(let address):
            self.init(IPv6SocketAddress(ip: address, port: port))
        }
    }
}

extension InetSocketAddress: SocketAddressProtocol {
    @_transparent
    public init?(_ storage: SocketAddressStorage) {
        switch storage.addressFamily {
        case sa_family_t(AF_INET):
            if let addr = IPv4SocketAddress(storage) {
                self.init(addr)
            }
        case sa_family_t(AF_INET6):
            if let addr = IPv6SocketAddress(storage) {
                self.init(addr)
            }
        default:
            return nil
        }
        return nil
    }

    @_transparent
    public func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T {
        switch self {
        case .v4(let addr):
            return try addr.withUnsafePointerToRawValue(body)
        case .v6(let addr):
            return try addr.withUnsafePointerToRawValue(body)
        }
    }
}

extension InetSocketAddress: Equatable {}

extension InetSocketAddress: Hashable {}

extension InetSocketAddress: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            switch self {
            case .v4(let addr):
                return addr.description
            case .v6(let addr):
                return addr.description
            }
        }
    }
}

extension InetSocketAddress: LosslessStringConvertible {
    public init?(_ description: String) {
        if let addr = IPv4SocketAddress(description) {
            self.init(addr)
            return
        }
        if let addr = IPv6SocketAddress(description) {
            self.init(addr)
            return
        }
        return nil
    }
}

@_transparent
public func == (lhs: InetSocketAddress, rhs: IPv4SocketAddress) -> Bool {
    return lhs == InetSocketAddress.v4(rhs)
}

@_transparent
public func == (lhs: InetSocketAddress, rhs: IPv6SocketAddress) -> Bool {
    return lhs == InetSocketAddress.v6(rhs)
}

// MARK: -

public struct IPv4SocketAddress: RawRepresentable {
    public let rawValue: sockaddr_in

    @inlinable
    public init(rawValue: sockaddr_in) {
        self.rawValue = rawValue
    }
}

extension IPv4SocketAddress {
    @inlinable
    public init(ip: IPv4Address, port: UInt16) {
        var addr = sockaddr_in()
        addr.sin_family = .init(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr = ip.rawValue
        self.init(rawValue: addr)
    }

    public var ipAddress: IPv4Address {
        @_transparent get {
            .init(rawValue: rawValue.sin_addr)
        }
    }

    public var port: UInt16 {
        @_transparent get {
            .init(bigEndian: rawValue.sin_port)
        }
    }
}

extension IPv4SocketAddress: SocketAddressProtocol {
    @inlinable
    public init?(_ storage: SocketAddressStorage) {
        switch storage.addressFamily {
        case sa_family_t(AF_INET):
            self.init(rawValue: storage.unsafeBitcast(as: sockaddr_in.self))
        default:
            return nil
        }
    }

    @_transparent
    public func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T {
        return try withUnsafePointer(to: rawValue) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
    }
}

extension IPv4SocketAddress: Equatable {
    @_transparent
    public static func == (lhs: IPv4SocketAddress, rhs: IPv4SocketAddress) -> Bool {
        return lhs.port == rhs.port && lhs.ipAddress == rhs.ipAddress
    }
}

extension IPv4SocketAddress: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ipAddress)
        hasher.combine(port)
    }
}

extension IPv4SocketAddress: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            "\(ipAddress.description):\(port.description)"
        }
    }
}

extension IPv4SocketAddress: LosslessStringConvertible {
    public init?(_ description: String) {
        let parts = description.split(separator: ":")
        if parts.count != 2 {
            return nil
        }
        guard let address = IPv4Address(String(parts[0])) else {
            return nil
        }
        guard let port = UInt16(parts[1]) else {
            return nil
        }
        self.init(ip: address, port: port)
    }
}

extension IPv4SocketAddress: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let address = try container.decode(IPv4Address.self)
        let port = try container.decode(UInt16.self)
        self.init(ip: address, port: port)
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(ipAddress)
        try container.encode(port)
    }
}

// MARK: -

public struct IPv6SocketAddress: RawRepresentable {
    public let rawValue: sockaddr_in6

    @inlinable
    public init(rawValue: sockaddr_in6) {
        self.rawValue = rawValue
    }
}

extension IPv6SocketAddress {
    @inlinable
    public init(ip: IPv6Address, port: UInt16, flowInfo: UInt32 = 0, scopeID: UInt32 = 0) {
        var addr = sockaddr_in6()
        addr.sin6_family = .init(AF_INET6)
        addr.sin6_port = port.bigEndian
        addr.sin6_flowinfo = flowInfo
        addr.sin6_addr = ip.rawValue
        addr.sin6_scope_id = scopeID
        rawValue = addr
    }

    public var ipAddress: IPv6Address {
        @_transparent get {
            .init(rawValue: rawValue.sin6_addr)
        }
    }

    public var port: UInt16 {
        @_transparent get {
            .init(bigEndian: rawValue.sin6_port)
        }
    }

    public var flowInfo: UInt32 {
        @_transparent get {
            rawValue.sin6_flowinfo
        }
    }

    public var scopeID: UInt32 {
        @_transparent get {
            rawValue.sin6_scope_id
        }
    }
}

extension IPv6SocketAddress: SocketAddressProtocol {
    @inlinable
    public init?(_ storage: SocketAddressStorage) {
        switch storage.addressFamily {
        case sa_family_t(AF_INET6):
            self.init(rawValue: storage.unsafeBitcast(as: sockaddr_in6.self))
        default:
            return nil
        }
    }

    @_transparent
    public func withUnsafePointerToRawValue<T>(
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> T
    ) rethrows -> T {
        return try withUnsafePointer(to: rawValue) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }
    }
}

extension IPv6SocketAddress: Equatable {
    @_transparent
    public static func == (lhs: IPv6SocketAddress, rhs: IPv6SocketAddress) -> Bool {
        return lhs.port == rhs.port &&
            lhs.flowInfo == rhs.flowInfo &&
            lhs.scopeID == rhs.scopeID &&
            lhs.ipAddress == rhs.ipAddress
    }
}

extension IPv6SocketAddress: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ipAddress)
        hasher.combine(port)
        hasher.combine(flowInfo)
        hasher.combine(scopeID)
    }
}

extension IPv6SocketAddress: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            "[\(ipAddress.description)]:\(port.description)"
        }
    }
}

extension IPv6SocketAddress: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        guard
            let bracketStartIndex = description.firstIndex(of: "["),
            let bracketEndIndex = description.lastIndex(of: "]"),
            let portStartIndex = description.lastIndex(of: ":"),
            bracketStartIndex == description.startIndex,
            portStartIndex == description.index(after: bracketEndIndex) else {
            return nil
        }

        // Parse IP address
        let ipRange = ClosedRange(uncheckedBounds: (
            description.index(after: bracketStartIndex),
            description.index(before: bracketEndIndex)
        ))
        let ipDescription = String(description[ipRange])
        guard let addr = IPv6Address(ipDescription) else {
            return nil
        }

        // Parse port
        let portRange = ClosedRange(uncheckedBounds: (
            description.index(after: portStartIndex),
            description.index(before: description.endIndex)
        ))
        let portDescription = String(description[portRange])
        guard let port = UInt16(portDescription) else {
            return nil
        }

        self.init(ip: addr, port: port)
    }
}

extension IPv6SocketAddress: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = IPv6SocketAddress(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid IPv6 socket address description: \(description)"
            )
        }
        self = address
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
        #if DEBUG
        if flowInfo != 0 || scopeID != 0 {
            print("""
            WARNING: IPv6SocketAddress attributes 'flowInfo' and 'scopeID'
            are not encoded and will be zero when decoded back!
            """
            )
        }
        #endif
    }
}
