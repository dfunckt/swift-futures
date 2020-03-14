//
//  AdaptiveQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

/// A FIFO queue, backed by a contiguous array, that is fast to dequeue
/// elements while also maintaining control over the overall allocated
/// capacity.
///
/// Like the native library's containers, it grows to accomodate new elements
/// by doubling its capacity when they won't fit, but it also dynamically
/// shrinks if the ratio of the number of elements over the whole capacity
/// becomes small enough. AdaptiveQueue is especially useful for cases where
/// the storage is long-lived and the load varying.
@usableFromInline
internal struct AdaptiveQueue<Element> {
    @usableFromInline typealias _Buffer = ContiguousArray<Element?>

    @usableFromInline var _buffer: _Buffer
    @usableFromInline var _head: Int

    @inlinable
    internal init() {
        _buffer = .init()
        _head = 0
    }

    @inlinable
    internal mutating func reserveCapacity(_ capacity: Int) {
        _buffer.reserveCapacity(capacity)
    }

    @inlinable
    internal var capacity: Int {
        return _buffer.count
    }

    @inlinable
    internal var count: Int {
        return _buffer.count - _head
    }

    @inlinable
    internal var isEmpty: Bool {
        return _buffer.count == _head
    }

    @inlinable
    internal mutating func move() -> AdaptiveQueue {
        let queue = self
        _buffer = .init()
        _head = 0
        return queue
    }

    @inlinable
    internal mutating func moveElements() -> [Element] {
        return .init(IteratorSequence(move()))
    }

    @inlinable
    @inline(__always)
    internal func forEach(_ body: (Element) throws -> Void) rethrows {
        for case let element? in _buffer {
            try body(element)
        }
    }

    @inlinable
    internal mutating func push(_ item: Element) {
        if let itemCount = _adjustedCapacity() {
            _resizeBuffer(capacity: itemCount)
        }
        _buffer.append(item)
    }

    @inlinable
    internal mutating func push<S: Sequence>(_ s: S) where S.Element == Element {
        if let itemCount = _adjustedCapacity(extra: s.underestimatedCount) {
            _resizeBuffer(capacity: itemCount)
        }
        _buffer.append(contentsOf: s.lazy.map(Optional.some))
    }

    @inlinable
    internal mutating func pop() -> Element? {
        if isEmpty {
            return nil
        }
        defer { _head += 1 }
        return _buffer[_head].move()
    }

    @inlinable
    @inline(__always)
    mutating func _adjustedCapacity(extra: Int = 0) -> Int? {
        let itemCount = max(count + extra, 1)
        if _buffer.count == _buffer.capacity, _buffer.count / itemCount >= 4 {
            // We are going to do an allocation anyway, so instead of letting
            // the buffer grow unbounded, check to see whether we can reclaim
            // some memory by purging read entries (i.e. `nil`). If the number
            // of read entries became the majority by 4, reallocate the
            // storage with half the current capacity.
            return itemCount * 2
        }
        return nil // no need to adjust
    }

    @usableFromInline
    @inline(never)
    mutating func _resizeBuffer(capacity: Int) {
        var storage = _Buffer()
        storage.reserveCapacity(capacity)
        storage.append(contentsOf: _buffer[_head..<_buffer.count])
        _buffer = storage
        _head = 0
    }
}

extension AdaptiveQueue: IteratorProtocol {
    @inlinable
    internal mutating func next() -> Element? {
        return pop()
    }
}
