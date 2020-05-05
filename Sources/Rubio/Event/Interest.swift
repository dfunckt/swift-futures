//
//  Interest.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public struct Interest: OptionSet, Equatable {
    public typealias RawValue = UInt8

    public var rawValue: RawValue

    /// - Precondition: `rawValue > 0`
    @inlinable
    public init(rawValue: RawValue) {
        precondition(rawValue > 0, "cannot create empty interest")
        self.rawValue = rawValue
    }
}

extension Interest {
    public static let all = Interest(rawValue: 0b11)
    public static let read = Interest(rawValue: 0b01)
    public static let write = Interest(rawValue: 0b10)

    public var isReadable: Bool {
        @_transparent get {
            rawValue & Interest.read.rawValue != 0
        }
    }

    public var isWritable: Bool {
        @_transparent get {
            rawValue & Interest.write.rawValue != 0
        }
    }
}
