//
//  AtomicUnboundedMPSCQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

/// A FIFO queue that is safe to share among multiple producers and a single
/// consumer.
///
/// This is an implementation of "non-intrusive MPSC queue" from 1024cores.net.
public final class AtomicUnboundedMPSCQueue<T>: AtomicUnboundedQueueProtocol {
    public typealias Element = T

    @usableFromInline typealias AtomicNode = AtomicReference<_Node>

    @usableFromInline
    final class _Node {
        @usableFromInline var _next: AtomicNode.RawValue = 0
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

    @usableFromInline var _head: AtomicNode.RawValue = 0 // producers
    @usableFromInline var _tail: _Node // consumer

    @inlinable
    public init() {
        let empty = _Node(nil)
        AtomicNode.initialize(&_head, to: empty)
        _tail = empty
    }

    @inlinable
    deinit {
        var cur: Optional = _tail
        while let current = cur {
            cur = AtomicNode.exchange(&current._next, nil)
        }
        AtomicNode.destroy(&_head)
    }

    @inlinable
    public var isEmpty: Bool {
        return AtomicNode.load(&_head, order: .relaxed) === _tail
    }

    @inlinable
    public func push(_ value: T) {
        let node = _Node(value)
        if let prev = AtomicNode.exchange(&_head, node, order: .acqrel) {
            AtomicNode.store(&prev._next, node, order: .release)
        } else {
            fatalError("unreachable")
        }
    }

    @inlinable
    public func pop() -> T? {
        var backoff = Backoff()
        let tail = _tail
        while true {
            if let next = AtomicNode.load(&tail._next, order: .acquire) {
                _tail = next
                assert(tail._value == nil)
                assert(next._value != nil)
                tail._value = next._value.take()
                return tail._value
            }
            if AtomicNode.load(&_head, order: .acquire) === tail {
                return nil
            }
            // the queue is in an inconsistent state. spin a little expecting
            // push will soon complete and we'll be able to pop an item out.
            // FIXME: return if we exhausted our budget
            _ = backoff.yield()
        }
    }
}
