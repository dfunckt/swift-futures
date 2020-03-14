//
//  TaskQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// An MPSC intrusive FIFO queue.
///
/// It uses `Task.nextReady` to link nodes together into a list.
@usableFromInline
internal final class TaskQueue<Scheduler: SchedulerProtocol> {
    // This is an implementation of "Intrusive MPSC node-based queue"
    // from 1024cores.net.

    @usableFromInline internal typealias Node = ScheduledTask<Scheduler>
    @usableFromInline internal typealias AtomicNode = Node.AtomicTask

    @usableFromInline var _tail: AtomicNode.RawValue = 0 // producers
    @usableFromInline var _head: Node // consumer
    @usableFromInline let _stub: Node // consumer

    @inlinable
    internal init() {
        let stub = Node(future: nil)
        AtomicNode.initialize(&_tail, to: stub)
        _head = stub
        _stub = stub
    }

    @inlinable
    internal var isEmpty: Bool {
        AtomicNode.load(&_tail) === _head
    }

    @inlinable
    internal func clear() {
        while let _ = dequeue() {
            // let it drop
        }
    }

    @inlinable
    internal func enqueue(_ task: Node) {
        AtomicNode.store(&task._nextReady, nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_tail, task, order: .acqrel) else {
            fatalError("unreachable")
        }
        // At this point, our queue is inconsistent -- its head and tail are
        // not parts of the same list. The list of nodes starting at `_head`
        // now ends at `prev` (which is not `tail` anymore). If the consumer
        // manages to consume it before the line below executes, it'll observe
        // that it's working on a "detached" list (because `prev` !== `_tail`)
        // and return `inconsistent`, in which case the caller should retry.
        AtomicNode.store(&prev._nextReady, task, order: .release)
    }

    @inlinable
    internal func dequeue() -> Node? {
        var backoff = Backoff()
        while true {
            var head = _head
            var next = AtomicNode.load(&head._nextReady, order: .acquire)

            if head === _stub {
                guard let task = next else {
                    return nil // empty
                }
                _head = task
                head = task
                next = AtomicNode.load(&head._nextReady, order: .acquire)
            }

            if let task = next {
                _head = task
                assert(head !== _stub)
                return head
            }

            if head === AtomicNode.load(&_tail, order: .relaxed) {
                enqueue(_stub)

                if let task = AtomicNode.load(&head._nextReady, order: .acquire) {
                    _head = task
                    return head
                }

                // empty
            }

            // inconsistent

            backoff.snooze()
        }
    }
}
