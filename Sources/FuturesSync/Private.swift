//
//  Private.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@inlinable
@inline(__always)
func isPowerOf2(_ n: Int) -> Bool {
    return UInt32(n).nonzeroBitCount == 1
}

extension Optional {
    @inlinable
    @_transparent
    @discardableResult
    mutating func move() -> Wrapped? {
        var value: Wrapped?
        Swift.swap(&self, &value)
        return value
    }
}
