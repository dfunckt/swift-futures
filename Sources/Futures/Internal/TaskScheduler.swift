//
//  TaskScheduler.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

final class _TaskScheduler<F: FutureProtocol> {
    private typealias ReadyQueue = _ReadyQueue<F>
    private typealias Node = ReadyQueue.Node

    private let _queue: ReadyQueue
    private var _head: Node?
    private var _nodeCache = AdaptiveQueue<Node>()
    @usableFromInline var _length = 0
    @usableFromInline let _waker: AtomicWaker

    init() {
        let waker = AtomicWaker()
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

            guard var f = node.future.move() else {
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
            let wasEnqueued = node.enqueued(false)
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
        let next = node.nextActive.move()
        let prev = node.prevActive.move()
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
        node.enqueued(true)
        node.future = nil
        if reusable {
            _nodeCache.push(node)
        }
    }
}

// MARK: - Private -

// This is an implementation of "Intrusive MPSC node-based queue" from 1024cores.net.
private final class _ReadyQueue<F: FutureProtocol> {
    typealias AtomicNode = AtomicReference<Node>

    struct NodeHeader {
        var future: F?
        var prevActive: Node?
        var nextActive: Node?
        var enqueued: AtomicBool.RawValue = true
        weak var queue: _ReadyQueue?
    }

    final class Node: ManagedBuffer<NodeHeader, AtomicUSize.RawValue>, WakerProtocol {
        struct NextNodeAccessor {
            let node: Node

            func load(order: AtomicLoadMemoryOrder = .seqcst) -> Node? {
                return node.withUnsafeMutablePointerToElements {
                    AtomicNode.load($0, order: order)
                }
            }

            func store(_ newNode: Node?, order: AtomicStoreMemoryOrder = .seqcst) {
                node.withUnsafeMutablePointerToElements {
                    AtomicNode.store($0, newNode, order: order)
                }
            }
        }

        deinit {
            withUnsafeMutablePointers {
                assert($0.pointee.future == nil)
                AtomicNode.destroy($1)
                $1.deinitialize(count: 1)
                $0.deinitialize(count: 1)
            }
        }

        var next: NextNodeAccessor {
            return .init(node: self)
        }

        var future: F? {
            get { return withUnsafeMutablePointerToHeader { $0.pointee.future } }
            set { withUnsafeMutablePointerToHeader { $0.pointee.future = newValue } }
        }

        var prevActive: Node? {
            get { return withUnsafeMutablePointerToHeader { $0.pointee.prevActive } }
            set { withUnsafeMutablePointerToHeader { $0.pointee.prevActive = newValue } }
        }

        var nextActive: Node? {
            get { return withUnsafeMutablePointerToHeader { $0.pointee.nextActive } }
            set { withUnsafeMutablePointerToHeader { $0.pointee.nextActive = newValue } }
        }

        @discardableResult
        func enqueued(_ flag: AtomicBool.RawValue) -> AtomicBool.RawValue {
            return withUnsafeMutablePointerToHeader {
                AtomicBool.exchange(&$0.pointee.enqueued, flag)
            }
        }

        func signal() {
            withUnsafeMutablePointerToHeader {
                guard let queue = $0.pointee.queue else {
                    return
                }
                if !AtomicBool.exchange(&$0.pointee.enqueued, true) {
                    queue.enqueue(self)
                    queue._waker.signal()
                }
            }
        }
    }

    private let _waker: AtomicWaker
    private var _head: AtomicNode.RawValue = 0 // producers
    private var _tail: Node // consumer
    private let _stub: Node // consumer

    init(waker: AtomicWaker) {
        let node = Node.create(minimumCapacity: 1) { _ in .init() }
        node.withUnsafeMutablePointers {
            AtomicBool.initialize(&$0.pointee.enqueued, to: true)
            AtomicNode.initialize($1, to: nil)
        }
        let stub = unsafeDowncast(node, to: Node.self)

        AtomicNode.initialize(&_head, to: stub)
        _waker = waker
        _tail = stub
        _stub = stub
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
        let node = Node.create(minimumCapacity: 1) { _ in
            .init()
        }
        node.withUnsafeMutablePointers {
            $0.pointee.queue = self
            $0.pointee.future = future
            AtomicBool.initialize(&$0.pointee.enqueued, to: true)
            AtomicNode.initialize($1, to: nil)
        }
        return unsafeDowncast(node, to: Node.self)
    }

    func enqueue(_ head: Node, _ tail: Node) {
        head.next.store(nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_head, head, order: .acqrel) else {
            fatalError("unreachable")
        }
        prev.next.store(tail, order: .release)
    }

    func enqueue(_ node: Node) {
        node.next.store(nil, order: .relaxed)
        guard let prev = AtomicNode.exchange(&_head, node, order: .acqrel) else {
            fatalError("unreachable")
        }
        // At this point, our queue contains a single item -- `_head` points
        // nowhere and the whole linked list of nodes is now terminated at
        // `prev`. If the consumer manages to consume the `prev` list before
        // the line below executes, it'll reach `prev` and see that it's no
        // longer working on the same list as the producer (because
        // `prev` !== `_head`) and it will return `inconsistent`.
        prev.next.store(node, order: .release)
    }

    func dequeue() -> Node? {
        var backoff = Backoff()
        while true {
            var tail = _tail
            var next = tail.next.load(order: .acquire)

            if tail === _stub {
                guard let node = next else {
                    return nil
                }
                _tail = node
                tail = node
                next = tail.next.load(order: .acquire)
            }

            if let node = next {
                _tail = node
                assert(tail !== _stub)
                return tail
            }

            if tail === AtomicNode.load(&_head, order: .acquire) {
                enqueue(_stub)

                if let node = tail.next.load(order: .acquire) {
                    _tail = node
                    return tail
                }
            }

            // FIXME: return if we exhausted our budget
            backoff.snooze()
        }
    }
}
