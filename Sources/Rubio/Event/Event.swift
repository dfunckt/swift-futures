//
//  Event.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

@usableFromInline
internal struct Event: RawRepresentable {
    @usableFromInline internal var rawValue: EventQueue.Selector.Event

    @inlinable
    internal init(rawValue: EventQueue.Selector.Event) {
        self.rawValue = rawValue
    }
}

extension Event {
    @inlinable
    internal var token: UInt {
        EventQueue.Selector.token(for: rawValue)
    }

    @inlinable
    internal var readiness: Readiness {
        var readiness: UInt8 = 0

        if EventQueue.Selector.isReadReady(rawValue) {
            readiness |= Readiness.readReady.rawValue
        }
        if EventQueue.Selector.isWriteReady(rawValue) {
            readiness |= Readiness.writeReady.rawValue
        }
        if EventQueue.Selector.isReadClosed(rawValue) {
            readiness |= Readiness.readClosed.rawValue
        }
        if EventQueue.Selector.isWriteClosed(rawValue) {
            readiness |= Readiness.writeClosed.rawValue
        }
        if EventQueue.Selector.isError(rawValue) {
            readiness |= Readiness.error.rawValue
        }

        return .init(rawValue: readiness)
    }
}

// MARK: -

@usableFromInline
internal struct Readiness: OptionSet, Equatable {
    @usableFromInline internal typealias RawValue = UInt8

    @usableFromInline internal var rawValue: RawValue

    @inlinable
    internal init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension Readiness {
    @usableFromInline internal static let readReady = Readiness(rawValue: 0b00001)
    @usableFromInline internal static let writeReady = Readiness(rawValue: 0b00010)
    @usableFromInline internal static let readClosed = Readiness(rawValue: 0b00100)
    @usableFromInline internal static let writeClosed = Readiness(rawValue: 0b01000)
    @usableFromInline internal static let error = Readiness(rawValue: 0b10000)

    @usableFromInline internal static let readable: Readiness = [readReady, readClosed, error]
    @usableFromInline internal static let writable: Readiness = [writeReady, writeClosed, error]
}

extension Readiness {
    @inlinable
    internal var isReadReady: Bool {
        @_transparent get {
            rawValue & Readiness.readReady.rawValue != 0
        }
    }

    @inlinable
    internal var isWriteReady: Bool {
        @_transparent get {
            rawValue & Readiness.writeReady.rawValue != 0
        }
    }

    @inlinable
    internal var isReadClosed: Bool {
        @_transparent get {
            rawValue & Readiness.readClosed.rawValue != 0
        }
    }

    @inlinable
    internal var isWriteClosed: Bool {
        @_transparent get {
            rawValue & Readiness.writeClosed.rawValue != 0
        }
    }

    @inlinable
    internal var isError: Bool {
        @_transparent get {
            rawValue & Readiness.error.rawValue != 0
        }
    }
}

extension Readiness {
    @inlinable
    internal var isReadable: Bool {
        @_transparent get {
            rawValue & Readiness.readable.rawValue != 0
        }
    }

    @inlinable
    internal var isWritable: Bool {
        @_transparent get {
            rawValue & Readiness.writable.rawValue != 0
        }
    }
}
