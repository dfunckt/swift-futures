//
//  EventList.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesIO
import FuturesPlatform

@usableFromInline
internal struct EventList {
    @usableFromInline internal typealias RawEvent = EventQueue.Selector.Event
    @usableFromInline internal typealias RawEventList = UnsafeMutableBufferPointer<RawEvent>

    @usableFromInline let _buffer: RawEventList
    @usableFromInline var _count = 0

    @inlinable
    internal init(capacity: Int) {
        _buffer = .allocate(capacity: capacity)
        _buffer.initialize(repeating: .init())
    }
}

extension EventList {
    @inlinable
    internal var count: Int {
        _count
    }

    @inlinable
    internal var isEmpty: Bool {
        _count == 0
    }

    @inlinable
    internal mutating func reset() {
        _count = 0
    }

    @inlinable
    internal func deallocate() {
        _buffer.deallocate()
    }
}

extension EventList: Sequence {
    @usableFromInline
    internal struct Iterator: IteratorProtocol {
        @usableFromInline typealias Element = Event

        @usableFromInline var _iter: RawEventList.Iterator

        @inlinable
        init(_ iter: RawEventList.Iterator) {
            _iter = iter
        }

        @inlinable
        mutating func next() -> Element? {
            return _iter.next().map(Event.init(rawValue:))
        }
    }

    @inlinable
    @_transparent
    internal func makeIterator() -> Iterator {
        let buffer = RawEventList(
            start: _buffer.baseAddress,
            count: _count
        )
        return .init(buffer.makeIterator())
    }
}

extension EventList {
    @inlinable
    @_transparent
    mutating func withPointerToRawEventList(
        _ block: (RawEventList) -> IOResult<CInt>
    ) -> IOResult<Void> {
        block(_buffer).map { _count = .init($0) }
    }
}
