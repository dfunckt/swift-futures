//
//  AtomicUnboundedSPSCQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

/// A FIFO queue that is safe to share between a single producer and a single
/// consumer.
public final class AtomicUnboundedSPSCQueue<T>: AtomicUnboundedQueueProtocol {
    // This is an implementation of "unbounded SPSC queue" from 1024cores.net,
    // with a modification for caching nodes lifted from Rust's stdlib.

    public typealias Element = T

    @usableFromInline typealias AtomicNode = AtomicReference<_Node>

    @usableFromInline
    final class _Node {
        @usableFromInline var _next: AtomicNode.RawValue = 0
        @usableFromInline var _cached = false
        @usableFromInline var _value: T?

        @inlinable
        init(_ value: T?) {
            AtomicNode.initialize(&_next, to: nil)
            _value = value
        }

        @inlinable
        deinit {
            AtomicNode.destroy(&_next)
        }
    }

    // producer
    @usableFromInline var _head: _Node
    @usableFromInline var _first: _Node
    @usableFromInline var _tailCopy: _Node

    // consumer
    @usableFromInline var _tail: _Node
    @usableFromInline var _tailPrev: AtomicNode.RawValue = 0
    @usableFromInline let _maxCached: Int
    @usableFromInline var _numCached: AtomicInt.RawValue = 0

    @inlinable
    public convenience init() {
        // 0 == no cache
        self.init(cacheCapacity: 0)
    }

    /// - Parameter cacheCapacity:
    ///     The maximum number of reusable nodes. `0` disables node reuse.
    @inlinable
    public init(cacheCapacity: Int) {
        let n1 = _Node(nil)
        let n2 = _Node(nil)
        AtomicNode.store(&n1._next, n2, order: .relaxed)

        _head = n2
        _first = n1
        _tailCopy = n1

        _tail = n2
        AtomicNode.initialize(&_tailPrev, to: n1)
        _maxCached = .init(UInt32(cacheCapacity))
    }

    @inlinable
    deinit {
        var cur: Optional = _first
        while let current = cur {
            cur = AtomicNode.exchange(&current._next, nil)
        }
        AtomicNode.destroy(&_tailPrev)
    }

    @inlinable
    public var isEmpty: Bool {
        return _head === _tail
    }

    @inlinable
    public func push(_ value: T) {
        let node = _allocNode(value)
        AtomicNode.store(&_head._next, node, order: .release)
        _head = node
    }

    @inlinable
    public func pop() -> Element? {
        let tail = _tail
        guard let next = AtomicNode.load(&tail._next, order: .acquire) else {
            return nil // empty
        }

        assert(tail._value == nil)
        assert(next._value != nil)
        let value = next._value.move()
        _tail = next

        if _maxCached == 0 {
            AtomicNode.store(&_tailPrev, tail, order: .release)
        } else {
            let count = AtomicInt.load(&_numCached, order: .relaxed)
            if count < _maxCached, !tail._cached {
                AtomicInt.store(&_numCached, count, order: .relaxed)
                tail._cached = true
            }
            if tail._cached {
                AtomicNode.store(&_tailPrev, tail, order: .release)
            } else {
                // swiftlint:disable:next force_unwrapping
                let prev = AtomicNode.load(&_tailPrev, order: .relaxed)!
                AtomicNode.store(&prev._next, next, order: .relaxed)
            }
        }

        return value
    }

    @inlinable
    func _allocNode(_ value: T) -> _Node {
        let node: _Node
        if _first !== _tailCopy {
            node = _first
            // swiftlint:disable:next force_unwrapping
            _first = AtomicNode.load(&node._next, order: .relaxed)!
        } else {
            // swiftlint:disable:next force_unwrapping
            _tailCopy = AtomicNode.load(&_tailPrev, order: .acquire)!
            if _first !== _tailCopy {
                node = _first
                // swiftlint:disable:next force_unwrapping
                _first = AtomicNode.load(&node._next, order: .relaxed)!
            } else {
                return _Node(value)
            }
        }
        node._value = value
        AtomicNode.destroy(&node._next, order: .relaxed)
        return node
    }
}
