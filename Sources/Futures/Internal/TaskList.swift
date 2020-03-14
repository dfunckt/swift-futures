//
//  TaskList.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

/// A non-concurrent intrusive doubly linked list.
///
/// It uses `Task.nextActive` and `Task.prevActive` to link nodes together
/// into a list.
@usableFromInline
internal struct TaskList<Scheduler: SchedulerProtocol> {
    @usableFromInline typealias Node = ScheduledTask<Scheduler>

    @usableFromInline var _tail: Node?
    @usableFromInline var _head: Node?
    @usableFromInline var _count = 0

    @inlinable
    internal init() {}

    @inlinable
    internal var first: Node? {
        _head
    }

    @inlinable
    internal var last: Node? {
        _tail
    }

    @inlinable
    internal var count: Int {
        _count
    }

    @inlinable
    internal var isEmpty: Bool {
        _count == 0
    }

    @inlinable
    internal mutating func prepend(_ node: Node) {
        assert(node.nextActive == nil)
        assert(node.prevActive == nil)
        assert(_head?.prevActive == nil)
        node.nextActive = _head
        _head?.prevActive = node
        _head = node
        if _tail == nil {
            _tail = node
        }
        _count += 1
    }

    @inlinable
    internal mutating func append(_ node: Node) {
        assert(node.nextActive == nil)
        assert(node.prevActive == nil)
        assert(_tail?.nextActive == nil)
        node.prevActive = _tail
        _tail?.nextActive = node
        _tail = node
        if _head == nil {
            _head = node
        }
        _count += 1
    }

    @inlinable
    internal mutating func insert(_ node: Node, before next: Node) {
        assert(node.nextActive == nil)
        assert(node.prevActive == nil)
        let prev = next.prevActive.move()
        node.prevActive = prev
        node.nextActive = next
        next.prevActive = node
        if let prev = prev {
            prev.nextActive = node
        } else {
            _head = node
        }
        if _tail == nil {
            _tail = node
        }
        _count += 1
    }

    @inlinable
    internal mutating func insert(_ node: Node, after prev: Node) {
        assert(node.nextActive == nil)
        assert(node.prevActive == nil)
        let next = prev.nextActive.move()
        node.prevActive = prev
        node.nextActive = next
        prev.nextActive = node
        if let next = next {
            next.prevActive = node
        } else {
            _tail = node
        }
        if _head == nil {
            _head = node
        }
        _count += 1
    }

    @inlinable
    internal mutating func remove(_ node: Node) {
        let next = node.nextActive.move()
        let prev = node.prevActive.move()
        assert(!(next == nil && prev == nil && node !== _head), "node is not part of list")
        if let next = next {
            next.prevActive = prev
        } else {
            _tail = prev
        }
        if let prev = prev {
            prev.nextActive = next
        } else {
            _head = next
        }
        _count -= 1
        assert(_count >= 0)
    }

    @inlinable
    internal mutating func removeFirst() -> Node? {
        if let curr = _head {
            remove(curr)
            return curr
        }
        return nil
    }

    @inlinable
    internal mutating func removeLast() -> Node? {
        if let curr = _tail {
            remove(curr)
            return curr
        }
        return nil
    }

    @inlinable
    internal mutating func removeAll() {
        var next = _head.move()
        while let node = next {
            node.prevActive = nil
            next = node.nextActive.move()
        }
        _tail = nil
        _count = 0
    }
}

extension TaskList {
    @usableFromInline typealias Batch = (first: Node, last: Node, count: Int)

    @inlinable
    func _makeBatch<I>(_ iter: inout I) -> Batch?
        where I: IteratorProtocol, I.Element == Node {
        guard let first = iter.next() else {
            return nil
        }
        assert(first.nextActive == nil)
        assert(first.prevActive == nil)
        var last = first
        var count = 1
        while let next = iter.next() {
            assert(next.nextActive == nil)
            assert(next.prevActive == nil)
            last.nextActive = next
            next.prevActive = last
            last = next
            count &+= 1
        }
        return (first, last, count)
    }

    @inlinable
    internal mutating func prepend<S>(contentsOf sequence: S)
        where S: Sequence, S.Element == Node {
        var iter = sequence.makeIterator()
        guard let batch = _makeBatch(&iter) else {
            return
        }
        batch.last.nextActive = _head
        _head?.prevActive = batch.last
        _head = batch.first
        if _tail == nil {
            _tail = batch.last
        }
        _count += batch.count
    }

    @inlinable
    internal mutating func append<S>(contentsOf sequence: S)
        where S: Sequence, S.Element == Node {
        var iter = sequence.makeIterator()
        guard let batch = _makeBatch(&iter) else {
            return
        }
        batch.first.prevActive = _tail
        _tail?.nextActive = batch.first
        _tail = batch.last
        if _head == nil {
            _head = batch.first
        }
        _count += batch.count
    }
}

extension TaskList {
    @usableFromInline
    internal struct ConsumingIterator: IteratorProtocol, Sequence {
        @usableFromInline var _node: Node?

        @inlinable
        init(node: Node?) {
            _node = node
        }

        @inlinable
        internal mutating func next() -> Node? {
            let next = _node.move()
            next?.prevActive = nil
            _node = next?.nextActive.move()
            return next
        }
    }

    @inlinable
    internal mutating func moveElements() -> ConsumingIterator {
        let head = _head.move()
        _tail = nil
        _count = 0
        return .init(node: head)
    }
}
