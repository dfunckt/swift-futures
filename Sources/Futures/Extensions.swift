//
//  Extensions.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Swift.Sequence {
    @inlinable
    public func makeStream() -> Stream._Private.Sequence<Self> {
        return .init(sequence: self)
    }
}

extension Swift.Array: StreamConvertible {}
extension Swift.ContiguousArray: StreamConvertible {}
extension Swift.Set: StreamConvertible {}
extension Swift.Dictionary: StreamConvertible {}

// MARK: - Private -

/// :nodoc:
public protocol _OptionalConvertible {
    associatedtype WrappedType
    nonmutating func _makeOptional() -> WrappedType?
}

/// :nodoc:
extension Swift.Optional: _OptionalConvertible {
    @_transparent
    public func _makeOptional() -> Wrapped? {
        return self
    }
}
