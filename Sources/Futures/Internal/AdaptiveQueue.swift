/// A FIFO queue that is fast to dequeue elements while also maintaining control
/// over the overall allocated capacity. Like the native library's containers,
/// it grows to accomodate new elements by doubling its capacity when they won't
/// fit, but it also dynamically shrinks if the ratio of the number of elements
/// over the whole capacity becomes small enough. This is especially useful for
/// cases where the storage is long-lived and the load varying.
@usableFromInline
struct _AdaptiveQueue<Element> {
    @usableFromInline typealias Buffer = ContiguousArray<Element?>

    @usableFromInline var _buffer: Buffer
    @usableFromInline var _head: Int
    @usableFromInline let _reclaimFactor: Int

    @inlinable
    init(reclaimFactor: Int = 4) {
        _buffer = .init()
        _head = 0
        _reclaimFactor = reclaimFactor
    }

    @inlinable
    var capacity: Int {
        return _buffer.count
    }

    @inlinable
    var count: Int {
        return _buffer.count - _head
    }

    @inlinable
    var isEmpty: Bool {
        return _buffer.count == _head
    }

    @inlinable
    func forEach(_ body: (Element) throws -> Void) rethrows {
        for case let element? in _buffer {
            try body(element)
        }
    }

    @inlinable
    mutating func reserveCapacity(_ capacity: Int) {
        _buffer.reserveCapacity(capacity)
    }

    @inlinable
    mutating func _adjustCapacity(offset: Int = 0) {
        let itemCount = max(count, 1) + offset

        if _buffer.count == _buffer.capacity,
            _buffer.count / itemCount >= _reclaimFactor {
            // We are going to do an allocation anyway, so instead of letting
            // the buffer grow unbounded, check to see whether we can reclaim
            // some memory by purging read entries (i.e. `nil`). If the number
            // of read entries became the majority by RECLAIM_FACTOR, reallocate
            // the storage with half the current size.
            var storage = Buffer()
            storage.reserveCapacity(itemCount * 2)
            storage.append(contentsOf: _buffer[_head..<_buffer.count])
            _buffer = storage
            _head = 0
        }
    }

    @inlinable
    mutating func push<S: Sequence>(_ s: S) where S.Element == Element {
        _adjustCapacity(offset: s.underestimatedCount)
        _buffer.append(contentsOf: s.lazy.map(Optional.some))
    }

    @inlinable
    mutating func push(_ item: Element) {
        _adjustCapacity()
        _buffer.append(item)
    }

    @inlinable
    mutating func pop() -> Element? {
        if isEmpty {
            return nil
        }
        let item = _buffer[_head]
        _buffer[_head] = nil
        _head += 1
        return item
    }

    @inlinable
    mutating func move() -> _AdaptiveQueue {
        let copy = self
        self = .init(reclaimFactor: _reclaimFactor)
        return copy
    }
}

extension _AdaptiveQueue {
    @usableFromInline
    struct _ConsumingIterator: IteratorProtocol, Sequence {
        @usableFromInline var _queue: _AdaptiveQueue

        @inlinable
        init(queue: _AdaptiveQueue) {
            _queue = queue
        }

        @inlinable
        mutating func next() -> Element? {
            return _queue.pop()
        }
    }

    @inlinable
    init(_ buffer: Buffer, _ head: Int, _ reclaimFactor: Int) {
        _buffer = buffer
        _head = head
        _reclaimFactor = reclaimFactor
    }

    @inlinable
    mutating func consume() -> _ConsumingIterator {
        let queue = _AdaptiveQueue(_buffer, _head, _reclaimFactor)
        _buffer = .init()
        _head = 0
        return .init(queue: queue)
    }
}
