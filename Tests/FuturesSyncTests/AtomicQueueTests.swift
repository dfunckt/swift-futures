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

    func testConcurrent() {
        let producerCount = supportsMultipleProducers ? CPU_COUNT : 1
        let consumerCount = supportsMultipleConsumers ? CPU_COUNT : 1

        let total = producerCount * iterations
        let sum = AtomicInt(0)
        let q = makeQueue()

        let group = DispatchGroup()
        let producers = DispatchQueue(label: "tests.queue-producer", attributes: .concurrent)
        let consumers = DispatchQueue(label: "tests.queue-consumer", attributes: .concurrent)

        var producerIter = (0..<producerCount).makeIterator()
        var consumerIter = (0..<consumerCount).makeIterator()
        var done = true

        // interleave spawning producers and consumers to workaround
        // GCD capping the number of concurrent blocks running in the
        // queues, which makes starvation of consumers possible
        repeat {
            done = true

            if producerIter.next() != nil {
                done = false
                producers.async(group: group, flags: .detached) {
                    for _ in 0..<iterations {
                        q.push(1)
                        Atomic.hardwarePause()
                    }
                }
            }

            if consumerIter.next() != nil {
                done = false
                consumers.async(group: group, flags: .detached) {
                    while sum.load() < total {
                        while let _ = q.pop() {
                            sum.fetchAdd(1, order: .relaxed)
                            Atomic.hardwarePause()
                        }
                        Atomic.hardwarePause()
                    }
                }
            }
        } while !done

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

    func testConcurrent() {
        let producerCount = max(1, supportsMultipleProducers ? CPU_COUNT : 1)
        let consumerCount = max(1, supportsMultipleConsumers ? CPU_COUNT : 1)

        let total = producerCount * iterations
        let sum = AtomicInt(0)
        let q = makeQueue(2)

        let group = DispatchGroup()
        let producers = DispatchQueue(label: "tests.queue-producer", attributes: .concurrent)
        let consumers = DispatchQueue(label: "tests.queue-consumer", attributes: .concurrent)

        var producerIter = (0..<producerCount).makeIterator()
        var consumerIter = (0..<consumerCount).makeIterator()
        var done = true

        // interleave spawning producers and consumers to workaround
        // GCD capping the number of concurrent blocks running in the
        // queues, which makes starvation of consumers possible
        repeat {
            done = true

            if producerIter.next() != nil {
                done = false
                producers.async(group: group, flags: .detached) {
                    for _ in 0..<iterations {
                        while !q.tryPush(1) {
                            Atomic.hardwarePause()
                        }
                        Atomic.hardwarePause()
                    }
                }
            }

            if consumerIter.next() != nil {
                done = false
                consumers.async(group: group, flags: .detached) {
                    while sum.load() < total {
                        while let _ = q.pop() {
                            sum.fetchAdd(1, order: .relaxed)
                            Atomic.hardwarePause()
                        }
                        Atomic.hardwarePause()
                    }
                }
            }
        } while !done

        group.wait()
        XCTAssertEqual(sum.load(), total)
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
    func testConcurrent() { tester.testConcurrent() }
}

final class AtomicUnboundedMPSCQueueTests: XCTestCase {
    private let tester = UnboundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: false,
        constructor: AtomicUnboundedMPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testConcurrent() { tester.testConcurrent() }
}

final class AtomicBoundedSPSCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: false,
        supportsMultipleConsumers: false,
        constructor: AtomicSPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testConcurrent() { tester.testConcurrent() }
}

final class AtomicBoundedSPMCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: false,
        supportsMultipleConsumers: true,
        constructor: AtomicSPMCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testConcurrent() { tester.testConcurrent() }
}

final class AtomicBoundedMPSCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: false,
        constructor: AtomicMPSCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testConcurrent() { tester.testConcurrent() }
}

final class AtomicBoundedMPMCQueueTests: XCTestCase {
    private let tester = BoundedQueueTester(
        supportsMultipleProducers: true,
        supportsMultipleConsumers: true,
        constructor: AtomicMPMCQueue<Int>.init
    )

    func testSync() { tester.testSync() }
    func testConcurrent() { tester.testConcurrent() }
}
