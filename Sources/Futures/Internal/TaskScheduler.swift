//
//  TaskScheduler.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

final class _TaskScheduler<F: FutureProtocol> {
    private typealias ReadyQueue = _ReadyQueue<F>
    private typealias AtomicNode = ReadyQueue.AtomicNode
    private typealias Node = ReadyQueue.Node

    private let _queue: ReadyQueue
    private var _head: Node?
    private var _nodeCache = _AdaptiveQueue<Node>()
    @usableFromInline var _length = 0
    @usableFromInline let _waker: _AtomicWaker

    init() {
        let waker = _AtomicWaker()
        _waker = waker
        _queue = ReadyQueue(waker: waker)
    }

    deinit {
        while let head = _head {
            _unlink(head)
            _release(head, reusable: false)
        }
    }

    @inlinable
    var count: Int {
        return _length
    }

    @inlinable
    var isEmpty: Bool {
        return _length == 0
    }

    func schedule<S: Sequence>(_ s: S) where S.Element == F {
        for f in s {
            schedule(f)
        }
    }

    func schedule(_ f: F) {
        let node = _allocNode(f)
        _link(node)
        _queue.enqueue(node)
    }

    @inlinable
    func register(_ waker: WakerProtocol) {
        _waker.register(waker)
    }

    // make sure you register a waker before invoking this method to
    // ensure wakeups are delivered properly.
    func pollNext(_ context: inout Context) -> Poll<F.Output?> {
        while true {
            guard let node = _queue.dequeue() else {
                if isEmpty {
                    return .ready(nil)
                }
                return .pending
            }

            guard var f = node.future.take() else {
                // This case only happens when `release()` was called for
                // this node before and couldn't be deallocated because it
                // was already enqueued in the ready to run queue. Ensure
                // that the call to `release()` really happened and retry.
                assert(node.nextActive == nil)
                assert(node.prevActive == nil)
                continue
            }

            // First unlink, then mark the node as not enqueued.
            // The `enqueued` flag prevents a waker signal from causing
            // the node to be re-linked back to the active list.
            _unlink(node)

            // Swap enqueued flag so that signalling the node during poll
            // properly adds it back to the ready-to-run queue.
            let wasEnqueued = Atomic.exchange(&node.enqueued, false)
            assert(wasEnqueued)

            var context = context.withWaker(node)
            switch f.poll(&context) {
            case .ready(let result):
                _release(node)
                return .ready(result)
            case .pending:
                node.future = f
                _link(node)
                continue
            }
        }
    }

    private func _allocNode(_ f: F) -> Node {
        if let node = _nodeCache.pop() {
            node.future = f
            return node
        }
        return _queue.makeNode(f)
    }

    private func _link(_ node: Node) {
        node.nextActive = _head
        _head?.prevActive = node
        _head = node
        _length += 1
    }

    private func _unlink(_ node: Node) {
        let next = node.nextActive.take()
        let prev = node.prevActive.take()
        next?.prevActive = prev
        if let prev = prev {
            prev.nextActive = next
        } else {
            _head = next
        }
        _length -= 1
    }

    private func _release(_ node: Node, reusable: Bool = true) {
        assert(node.nextActive == nil)
        assert(node.prevActive == nil)
        Atomic.store(&node.enqueued, true, order: .relaxed)
        node.future = nil
        if reusable {
            _nodeCache.push(node)
        }
    }
}

// MARK: - Private -

// This is an implementation of "Intrusive MPSC node-based queue" from 1024cores.net.
private final class _ReadyQueue<F: FutureProtocol> {
    typealias AtomicNode = AtomicRef<Node>

    final class Node: WakerProtocol {
        private weak var _queue: _ReadyQueue?
        var enqueued: AtomicBool.RawValue = true
        var next: AtomicNode.RawValue = 0

        var prevActive: Node?
        var nextActive: Node?

        var future: F?

        init() {
            Atomic.initialize(&enqueued, to: true)
            AtomicNode.initialize(&next, to: nil)
        }

        convenience init(_ queue: _ReadyQueue, _ future: F) {
            self.init()
            _queue = queue
            self.future = future
        }

        deinit {
            assert(future == nil)
            AtomicNode.destroy(&next)
        }

        func signal() {
            guard let queue = _queue else {
                return
            }
            if !Atomic.exchange(&enqueued, true) {
                queue.enqueue(self)
                queue._waker.signal()
            }
        }
    }

    private let _waker: _AtomicWaker
    private var _head: AtomicNode.RawValue = 0 // producers
    private var _tail: Node // consumer
    private let _stub: Node // consumer

    init(waker: _AtomicWaker) {
        let stub = Node()
        AtomicNode.initialize(&_head, to: stub)
        _tail = stub
        _stub = stub
        _waker = waker
    }

    deinit {
        while let _ = dequeue() {
            // just let it deinit
        }
        AtomicNode.destroy(&_head)
    }

    var isEmpty: Bool {
        return AtomicNode.load(&_head, order: .relaxed) === _tail
    }

    func makeNode(_ future: F) -> Node {
        return .init(self, future)
    }

    func enqueue(_ head: Node, _ tail: Node) {
        AtomicNode.store(&head.next, nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_head, head, order: .acqrel) else {
            fatalError("unreachable")
        }
        AtomicNode.store(&prev.next, tail, order: .release)
    }

    func enqueue(_ node: Node) {
        AtomicNode.store(&node.next, nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_head, node, order: .acqrel) else {
            fatalError("unreachable")
        }
        // At this point, our queue contains a single item -- `_head` points
        // nowhere and the whole linked list of nodes is now terminated at
        // `prev`. If the consumer manages to consume the `prev` list before
        // the line below executes, it'll reach `prev` and see that it's no
        // longer working on the same list as the producer (because
        // `prev` !== `_head`) and it will return `inconsistent`.
        AtomicNode.store(&prev.next, node, order: .release)
    }

    func dequeue() -> Node? {
        var backoff = Backoff()
        while true {
            var tail = _tail
            var next = AtomicNode.load(&tail.next, order: .acquire)

            if tail === _stub {
                guard let node = next else {
                    return nil
                }
                _tail = node
                tail = node
                next = AtomicNode.load(&tail.next, order: .acquire)
            }

            if let node = next {
                _tail = node
                assert(tail !== _stub)
                return tail
            }

            if tail === AtomicNode.load(&_head, order: .acquire) {
                enqueue(_stub)

                if let node = AtomicNode.load(&tail.next, order: .acquire) {
                    _tail = node
                    return tail
                }
            }

            backoff.yield()
        }
    }
}
