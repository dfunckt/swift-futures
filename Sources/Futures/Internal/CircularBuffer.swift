//
//  CircularBuffer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@usableFromInline
struct _CircularBuffer<Element> {
    @usableFromInline typealias Buffer = ContiguousArray<Element?>

    @usableFromInline var _buffer: Buffer
    @usableFromInline let _capacity: Int
    @usableFromInline var _head: Int // write pointer
    @usableFromInline var _tail: Int // read pointer

    @inlinable
    var _bufferCapacity: Int {
        return _buffer.count
    }

    @inlinable
    var _mask: Int {
        return _bufferCapacity - 1
    }

    @inlinable
    init(capacity: Int) {
        let capacity = Int(UInt32(capacity))
        _buffer = .init(repeating: nil, count: _nextPowerOf2(capacity))
        _capacity = capacity
        _head = 0
        _tail = 0
    }

    @inlinable
    init(_buffer: Buffer, _ capacity: Int, _ head: Int, _ tail: Int) {
        self._buffer = _buffer
        _capacity = capacity
        _head = head
        _tail = tail
    }

    @inlinable
    var count: Int {
        return _head - _tail
    }

    @inlinable
    var capacity: Int {
        return _capacity
    }

    @inlinable
    var isEmpty: Bool {
        return _head == _tail
    }

    @inlinable
    func copyElements() -> [Element] {
        return prefix(count)
    }

    @inlinable
    func prefix(_ maxCount: Int) -> [Element] {
        var elements = [Element]()
        elements.reserveCapacity(maxCount)
        var count = maxCount
        var tail = _tail
        while tail < _head, count > 0 {
            if let element = _buffer[tail & _mask] {
                count -= 1
                elements.append(element)
            }
            tail += 1
        }
        return elements
    }

    @inlinable
    mutating func tryPush(_ element: Element) -> Bool {
        if count == capacity {
            return false
        }
        _buffer[_head & _mask] = element
        _head += 1
        return true
    }

    @inlinable
    mutating func push(_ element: Element, expand: Bool = true) {
        if count == _bufferCapacity {
            if expand {
                _adjustCapacity()
            } else {
                _ = pop()
            }
        }
        _buffer[_head & _mask] = element
        _head += 1
    }

    @inlinable
    mutating func pop() -> Element? {
        if isEmpty {
            _head = 0
            _tail = 0
            return nil
        }
        let element = _buffer[_tail & _mask].take()
        _tail += 1
        return element
    }

    @usableFromInline
    mutating func _adjustCapacity() {
        var storage: Buffer = []
        let newCapacity = _bufferCapacity << 1
        let head = _tail & _mask
        storage.reserveCapacity(newCapacity)
        storage.append(contentsOf: _buffer[head..<_bufferCapacity])
        if head > 0 {
            storage.append(contentsOf: _buffer[0..<head])
        }
        storage.append(contentsOf: repeatElement(nil, count: newCapacity - storage.count))
        _head = _bufferCapacity
        _tail = 0
        _buffer = storage
    }
}

extension _CircularBuffer {
    @usableFromInline
    struct ConsumingIterator: IteratorProtocol {
        @usableFromInline var _queue: _CircularBuffer

        @inlinable
        init(queue: _CircularBuffer) {
            _queue = queue
        }

        @inlinable
        mutating func next() -> Element? {
            return _queue.pop()
        }

        @inlinable
        func makeSequence() -> IteratorSequence<ConsumingIterator> {
            return IteratorSequence(self)
        }
    }

    @inlinable
    mutating func consume() -> ConsumingIterator {
        let queue = _CircularBuffer(_buffer: _buffer, _capacity, _head, _tail)
        _buffer = .init(repeating: nil, count: _bufferCapacity)
        _head = 0
        _tail = 0
        return .init(queue: queue)
    }
}
