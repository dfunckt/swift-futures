//
//  Bitset.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@usableFromInline
internal protocol Bitset: ExpressibleByIntegerLiteral, OptionSet
    where RawValue: FixedWidthInteger {}

extension Bitset where RawValue == IntegerLiteralType {
    @usableFromInline
    @_transparent
    internal init(integerLiteral value: Self.IntegerLiteralType) {
        self = .init(rawValue: value)
    }
}

extension Bitset {
    @inlinable
    internal static var empty: Self {
        @_transparent get { 0 }
    }

    @usableFromInline
    @_transparent
    internal static func | (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.union(rhs)
    }

    @usableFromInline
    @_transparent
    internal static func & (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.intersection(rhs)
    }

    @usableFromInline
    @_transparent
    internal static func ^ (_ lhs: Self, _ rhs: Self) -> Self {
        return lhs.symmetricDifference(rhs)
    }

    @usableFromInline
    @_transparent
    internal static prefix func ~ (_ x: Self) -> Self {
        return .init(rawValue: ~x.rawValue)
    }
}
