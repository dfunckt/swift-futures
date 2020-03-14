//
//  TaskStack.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

/// A non-concurrent intrusive LIFO queue.
@usableFromInline
internal struct TaskStack<Scheduler: SchedulerProtocol> {
    @usableFromInline typealias Node = ScheduledTask<Scheduler>

    @usableFromInline var _head: Node?
    @usableFromInline var _count = 0

    @inlinable
    internal init() {}

    @inlinable
    internal var count: Int {
        _count
    }

    @inlinable
    internal var isEmpty: Bool {
        _count == 0
    }

    @inlinable
    internal mutating func push(_ node: Node) {
        node.nextActive = _head
        _head = node
        _count += 1
    }

    @inlinable
    internal mutating func pop() -> Node? {
        let node = _head.move()
        _head = node?.nextActive.move()
        if node != nil {
            _count -= 1
        }
        return node
    }

    @inlinable
    internal mutating func clear() {
        var next = _head.move()
        while let node = next {
            next = node.nextActive.move()
        }
        _count = 0
    }
}

extension TaskStack {
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
            _node = next?.nextActive.move()
            return next
        }
    }

    @inlinable
    internal mutating func moveElements() -> ConsumingIterator {
        let head = _head.move()
        _count = 0
        return .init(node: head)
    }
}
