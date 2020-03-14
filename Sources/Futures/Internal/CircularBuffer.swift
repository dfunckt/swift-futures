//
//  CircularBuffer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

@usableFromInline
internal struct CircularBuffer<Element> {
    @usableFromInline typealias _Buffer = ContiguousArray<Element?>

    @usableFromInline var _buffer: _Buffer
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
    internal init(capacity: Int) {
        let capacity = Int(UInt32(capacity))
        _buffer = .init(repeating: nil, count: nextPowerOf2(capacity))
        _capacity = capacity
        _head = 0
        _tail = 0
    }

    @inlinable
    internal mutating func destroy() {
        _buffer = .init()
        _head = 0
        _tail = 0
    }

    @inlinable
    internal var count: Int {
        return _head - _tail
    }

    @inlinable
    internal var capacity: Int {
        return _capacity
    }

    @inlinable
    internal var isEmpty: Bool {
        return _head == _tail
    }

    @inlinable
    internal mutating func move() -> CircularBuffer {
        let queue = self
        _buffer = .init(repeating: nil, count: _bufferCapacity)
        _head = 0
        _tail = 0
        return queue
    }

    @inlinable
    internal mutating func moveElements() -> [Element] {
        return .init(IteratorSequence(move()))
    }

    @inlinable
    internal func copyElements() -> [Element] {
        return prefix(count)
    }

    @inlinable
    internal func prefix(_ maxCount: Int) -> [Element] {
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
    internal mutating func tryPush(_ element: Element) -> Bool {
        if count == capacity {
            return false
        }
        _buffer[_head & _mask] = element
        _head += 1
        return true
    }

    @inlinable
    internal mutating func push(_ element: Element, expand: Bool = true) {
        if count == _bufferCapacity {
            if expand {
                _adjustCapacity()
            } else {
                _tail += 1
            }
        }
        _buffer[_head & _mask] = element
        _head += 1
    }

    @inlinable
    internal mutating func pop() -> Element? {
        if isEmpty {
            _head = 0
            _tail = 0
            return nil
        }
        defer { _tail += 1 }
        return _buffer[_tail & _mask].move()
    }

    @usableFromInline
    @inline(never)
    mutating func _adjustCapacity() {
        var storage: _Buffer = []
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

extension CircularBuffer: IteratorProtocol {
    @inlinable
    internal mutating func next() -> Element? {
        return pop()
    }
}
