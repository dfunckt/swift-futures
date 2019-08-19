//
//  AtomicQueueTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync
import FuturesTestSupport
import XCTest

private let iterations = 10_000

private final class UnboundedQueueTester<Queue: AtomicUnboundedQueueProtocol> where Queue.Element == Int {
    typealias Constructor = () -> Queue

    let supportsMultipleProducers: Bool
    let supportsMultipleConsumers: Bool
    let makeQueue: Constructor

    init(supportsMultipleProducers: Bool, supportsMultipleConsumers: Bool, constructor: @escaping Constructor) {
        self.supportsMultipleProducers = supportsMultipleProducers
        self.supportsMultipleConsumers = supportsMultipleConsumers
        makeQueue = constructor
    }

    func testSync() {
        let q = makeQueue()
        q.push(0)
        XCTAssertEqual(q.pop(), 0)
        XCTAssertNil(q.pop())
        XCTAssertNil(q.pop())
        q.push(0)
        XCTAssertEqual(q.pop(), 0)
        XCTAssertNil(q.pop())
        XCTAssertNil(q.pop())
    }

    func testThreaded() {
        let producerCount = supportsMultipleProducers ? max(2, CPU_COUNT / 2) : 1
        let consumerCount = supportsMultipleConsumers ? max(2, CPU_COUNT / 2) : 1

        let total = producerCount * (1...iterations).reduce(into: 0, +=)
        let sum = AtomicInt(0)
        let q = makeQueue()

        let group = DispatchGroup()
        let producers = DispatchQueue(label: "tests.queue-producer", attributes: .concurrent)
        let consumers = DispatchQueue(label: "tests.queue-consumer", attributes: .concurrent)

        for _ in 0..<producerCount {
            producers.async(group: group, flags: .detached) {
                for i in 1...iterations {
                    q.push(i)
                    Atomic.hardwarePause()
                }
            }
        }
        for _ in 0..<consumerCount {
            consumers.async(group: group, flags: .detached) {
                while sum.load() < total {
                    while let i = q.pop() {
                        sum.fetchAdd(i, order: .relaxed)
                    }
                    Atomic.hardwarePause()
                }
            }
        }

        group.wait()
        XCTAssertEqual(sum.load(), total)
        XCTAssertNil(q.pop())
    }
}

private final class BoundedQueueTester<Queue: AtomicQueueProtocol> where Queue.Element == Int {
    typealias Constructor = (_ capacity: Int) -> Queue

    let supportsMultipleProducers: Bool
    let supportsMultipleConsumers: Bool
    let makeQueue: Constructor

    init(supportsMultipleProducers: Bool, supportsMultipleConsumers: Bool, constructor: @escaping Constructor) {
        self.supportsMultipleProducers = supportsMultipleProducers
        self.supportsMultipleConsumers = supportsMultipleConsumers
        makeQueue = constructor
    }

    func testSync() {
        let q = makeQueue(2)
        XCTAssert(q.tryPush(0))
        XCTAssert(q.tryPush(1))
        XCTAssertFalse(q.tryPush(1))
        XCTAssertEqual(q.pop(), 0)
        XCTAssertEqual(q.pop(), 1)
        XCTAssertNil(q.pop())
        XCTAssertNil(q.pop())
        XCTAssert(q.tryPush(0))
        XCTAssertEqual(q.pop(), 0)
        XCTAssertNil(q.pop())
        XCTAssertNil(q.pop())
    }

    func testThreaded() {
        let producerCount = max(1, supportsMultipleProducers ? CPU_COUNT / 2 : 1)
        let consumerCount = max(1, supportsMultipleConsumers ? CPU_COUNT / 2 : 1)

        let total = producerCount * (1...iterations).reduce(into: 0, +=)
        let sum = AtomicInt(0)
        let q = makeQueue(2)

        let group = DispatchGroup()
        let producers = DispatchQueue(label: "tests.queue-producer", attributes: .concurrent)
        let consumers = DispatchQueue(label: "tests.queue-consumer", attributes: .concurrent)

        for _ in 0..<producerCount {
            producers.async(group: group, flags: .detached) {
                for i in 1...iterations {
                    while !q.tryPush(i) {
                        Atomic.hardwarePause()
                    }
                }
            }
        }
        for _ in 0..<consumerCount {
            consumers.async(group: group, flags: .detached) {
                while sum.load() < total {
                    while let i = q.pop() {
                        sum.fetchAdd(i, order: .relaxed)
                    }
                    Atomic.hardwarePause()
                }
            }
        }

        group.wait()
        XCTAssertEqual(sum.load(), total)
        XCTAssertNil(q.pop())
    }

    // Tests whether the queue is linearizable. Only relevant to MPMC. See:
    // https://github.com/stjepang/rfcs-crossbeam/blob/df5614b104c/text/2017-11-09-channel.md#array-based-flavor
    func testLinearizable() {
        XCTAssert(supportsMultipleProducers && supportsMultipleConsumers)

        let concurrency = 4
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "tests.queue", attributes: .concurrent)
        let q = makeQueue(concurrency)

        for _ in 0..<concurrency {
            queue.async(group: group, flags: .detached) {
                for _ in 0..<iterations {
                    XCTAssert(q.tryPush(0))
                    XCTAssertNotNil(q.pop())
                }
            }
        }

        group.wait()
        XCTAssertNil(q.pop())
    }
}

final class AtomicUnboundedSPSCQueueTests: XCTestCase {
    private let tester = UnboundedQueueTester(
        supportsMultipleProducers: false,
        supportsMultipleConsumers: false,
        constructor: AtomicUnboundedSPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
}

final class AtomicUnboundedMPSCQueueTests: XCTestCase {
    private let tester = UnboundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: false,
        constructor: AtomicUnboundedMPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
}

final class AtomicBoundedSPSCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: false,
        supportsMultipleConsumers: false,
        constructor: AtomicSPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
}

final class AtomicBoundedSPMCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: false,
        supportsMultipleConsumers: true,
        constructor: AtomicSPMCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
}

final class AtomicBoundedMPSCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: false,
        constructor: AtomicMPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
}

final class AtomicBoundedMPMCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: true,
        constructor: AtomicMPMCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testThreaded() { tester.testThreaded() }
    func _testLinearizable() { tester.testLinearizable() }
}
