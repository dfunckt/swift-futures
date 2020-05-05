//
//  InetAddress.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

//          InetAddress
//         ______|______
//        /             \
//  IPv4Address     IPv6Address

public enum InetAddress {
    case v4(IPv4Address)
    case v6(IPv6Address)
}

extension InetAddress {
    @inlinable
    public init(_ address: IPv4Address) {
        self = .v4(address)
    }

    @inlinable
    public init(_ address: IPv6Address) {
        self = .v6(address)
    }
}

extension InetAddress {
    @_transparent
    public init(_ ip: StaticString) {
        if let ip = IPv4Address(ip.description) {
            self = .v4(ip)
        } else if let ip = IPv6Address(ip.description) {
            self = .v6(ip)
        } else {
            fatalError("invalid IP address: \(ip)")
        }
    }
}

extension InetAddress: Equatable {}

extension InetAddress: Hashable {}

extension InetAddress: CustomStringConvertible {
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

extension InetAddress: LosslessStringConvertible {
    @_transparent
    public init?(_ description: String) {
        if let ip = IPv4Address(description) {
            self = .v4(ip)
        } else if let ip = IPv6Address(description) {
            self = .v6(ip)
        } else {
            return nil
        }
    }
}

extension InetAddress: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = InetAddress(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid IP address description: \(description)"
            )
        }
        self = address
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

@_transparent
public func == (lhs: InetAddress, rhs: IPv4Address) -> Bool {
    return lhs == InetAddress.v4(rhs)
}

@_transparent
public func == (lhs: InetAddress, rhs: IPv6Address) -> Bool {
    return lhs == InetAddress.v6(rhs)
}

// MARK: -

public struct IPv4Address: RawRepresentable {
    public let rawValue: in_addr

    @inlinable
    public init(rawValue: in_addr) {
        self.rawValue = rawValue
    }
}

extension IPv4Address {
    public static let unspecified = IPv4Address(rawValue: .any)
    public static let localhost = IPv4Address(rawValue: .loopback)
    public static let broadcast = IPv4Address(rawValue: .broadcast)
}

extension IPv4Address {
    @inlinable
    public init(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) {
        let a: in_addr_t = (
            in_addr_t(a) << 24 |
                in_addr_t(b) << 16 |
                in_addr_t(c) << 8 |
                in_addr_t(d)
        )
        self.init(rawValue: .init(s_addr: a.bigEndian))
    }

    public var octets: (UInt8, UInt8, UInt8, UInt8) {
        @_transparent get {
            withUnsafeBytes(of: rawValue) {
                ($0[0], $0[1], $0[2], $0[3])
            }
        }
    }
}

extension IPv4Address {
    @inlinable
    public init?(_ ipv6: IPv6Address) {
        switch ipv6.segments {
        case (0, 0, 0, 0, 0, let f, let g, let h) where f == 0 || f == 0xFFFF:
            self.init(
                UInt8(g >> 8), UInt8(truncatingIfNeeded: g),
                UInt8(h >> 8), UInt8(truncatingIfNeeded: h)
            )
        default:
            return nil
        }
    }
}

extension IPv4Address: Equatable {
    @_transparent
    public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        return lhs.rawValue.s_addr == rhs.rawValue.s_addr
    }
}

extension IPv4Address: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.s_addr)
    }
}

extension IPv4Address: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            inet_ntop(rawValue)
        }
    }
}

extension IPv4Address: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        guard let addr = inet_pton(description) else {
            return nil
        }
        self.init(rawValue: addr)
    }
}

extension IPv4Address: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = IPv4Address(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid IPv4 address description: \(description)"
            )
        }
        self = address
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

// MARK: -

public struct IPv6Address: RawRepresentable {
    public let rawValue: in6_addr

    @inlinable
    public init(rawValue: in6_addr) {
        self.rawValue = rawValue
    }
}

extension IPv6Address {
    public static let unspecified = IPv6Address(rawValue: .any)
    public static let localhost = IPv6Address(rawValue: .loopback)
}

extension IPv6Address {
    @inlinable
    public init(_ bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) {
        var addr = in6_addr()
        withUnsafeMutableBytes(of: &addr) { dst in
            withUnsafeBytes(of: bytes) { src in
                dst.copyMemory(from: src)
            }
        }
        self.init(rawValue: addr)
    }

    @_transparent
    public init(_ a: UInt16, _ b: UInt16, _ c: UInt16, _ d: UInt16, _ e: UInt16, _ f: UInt16, _ g: UInt16, _ h: UInt16) {
        self.init((
            UInt8(a >> 8), UInt8(truncatingIfNeeded: a),
            UInt8(b >> 8), UInt8(truncatingIfNeeded: b),
            UInt8(c >> 8), UInt8(truncatingIfNeeded: c),
            UInt8(d >> 8), UInt8(truncatingIfNeeded: d),
            UInt8(e >> 8), UInt8(truncatingIfNeeded: e),
            UInt8(f >> 8), UInt8(truncatingIfNeeded: f),
            UInt8(g >> 8), UInt8(truncatingIfNeeded: g),
            UInt8(h >> 8), UInt8(truncatingIfNeeded: h)
        ))
    }

    public var segments: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) {
        @_transparent get {
            withUnsafeBytes(of: rawValue) {
                return (
                    UInt16(bigEndian: UInt16($0[0]) | UInt16($0[1]) << 8),
                    UInt16(bigEndian: UInt16($0[2]) | UInt16($0[3]) << 8),
                    UInt16(bigEndian: UInt16($0[4]) | UInt16($0[5]) << 8),
                    UInt16(bigEndian: UInt16($0[6]) | UInt16($0[7]) << 8),
                    UInt16(bigEndian: UInt16($0[8]) | UInt16($0[9]) << 8),
                    UInt16(bigEndian: UInt16($0[10]) | UInt16($0[11]) << 8),
                    UInt16(bigEndian: UInt16($0[12]) | UInt16($0[13]) << 8),
                    UInt16(bigEndian: UInt16($0[14]) | UInt16($0[15]) << 8)
                )
            }
        }
    }
}

extension IPv6Address {
    @inlinable
    public init(_ ipv4: IPv4Address) {
        let octets = ipv4.octets
        self.init((
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            octets.0, octets.1, octets.2, octets.3
        ))
    }

    @inlinable
    public init(mapping ipv4: IPv4Address) {
        let octets = ipv4.octets
        self.init((
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0xFF, 0xFF,
            octets.0, octets.1, octets.2, octets.3
        ))
    }
}

extension IPv6Address: Equatable {
    @_transparent
    public static func == (lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        return withUnsafePointer(to: lhs.rawValue) { l in
            withUnsafePointer(to: rhs.rawValue) { r in
                memcmp(l, r, 16) == 0
            }
        }
    }
}

extension IPv6Address: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: rawValue) {
            hasher.combine(bytes: $0)
        }
    }
}

extension IPv6Address: CustomStringConvertible {
    public var description: String {
        @_transparent get {
            inet6_ntop(rawValue)
        }
    }
}

extension IPv6Address: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        guard let addr = inet6_pton(description) else {
            return nil
        }
        self.init(rawValue: addr)
    }
}

extension IPv6Address: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)
        guard let address = IPv6Address(description) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "invalid IPv6 address description: \(description)"
            )
        }
        self = address
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
