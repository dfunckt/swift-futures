//
//  AtomicList.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public protocol AtomicListNode: AnyObject {
    func withAtomicPointerToNextNode<R>(_ block: (AtomicReference<Self>.Pointer) -> R) -> R
}

/// An unbounded node-based MPSC queue.
public final class AtomicList<Node: AtomicListNode> {
    // This is an implementation of "Intrusive MPSC node-based queue"
    // from 1024cores.net.

    @usableFromInline typealias AtomicNode = AtomicReference<Node>

    @usableFromInline var _tail: AtomicNode.RawValue = 0 // producers
    @usableFromInline var _head: Node // consumer
    @usableFromInline let _stub: Node // consumer

    @inlinable
    public init(stub: Node) {
        AtomicNode.initialize(&_tail, to: stub)
        _head = stub
        _stub = stub
    }

    @inlinable
    public var isEmpty: Bool {
        _head === AtomicNode.load(&_tail, order: .relaxed)
    }

    @inlinable
    public func clear() {
        while let _ = dequeue() {
            Atomic.hardwarePause()
        }
    }

    @inlinable
    public func enqueue(_ node: Node) {
        node.storeNext(nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_tail, node, order: .acqrel) else {
            fatalError("unreachable")
        }
        // At this point, our queue is inconsistent -- its head and tail are
        // not parts of the same list. The list of nodes starting at `_head`
        // now ends at `prev` (which is not `tail` anymore). If the consumer
        // manages to consume it before the line below executes, it'll observe
        // that it's working on a "detached" list (because `prev` !== `_tail`)
        // and return `inconsistent`, in which case the caller should retry.
        prev.storeNext(node, order: .release)
    }

    @inlinable
    public func dequeue() -> Node? {
        var backoff = Backoff()
        while true {
            var head = _head
            var next = head.loadNext(order: .acquire)

            if head === _stub {
                guard let node = next else {
                    return nil // empty
                }
                _head = node
                head = node
                next = head.loadNext(order: .acquire)
            }

            if let node = next {
                _head = node
                assert(head !== _stub)
                return head
            }

            if head === AtomicNode.load(&_tail, order: .relaxed) {
                enqueue(_stub)

                if let node = head.loadNext(order: .acquire) {
                    _head = node
                    return head
                }
            }

            backoff.snooze()
        }
    }
}

extension AtomicListNode {
    @inlinable
    @_transparent
    func loadNext(order: AtomicLoadMemoryOrder) -> Self? {
        withAtomicPointerToNextNode {
            AtomicReference<Self>.load($0, order: order)
        }
    }

    @inlinable
    @_transparent
    func storeNext(_ node: Self?, order: AtomicStoreMemoryOrder) {
        withAtomicPointerToNextNode {
            AtomicReference<Self>.store($0, node, order: order)
        }
    }

    @inlinable
    @_transparent
    func exchangeNext(_ node: Self?, order: AtomicMemoryOrder) -> Self? {
        withAtomicPointerToNextNode {
            AtomicReference<Self>.exchange($0, node, order: order)
        }
    }
}
