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
