//
//  ExecutorTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesTestSupport
import XCTest

private struct Spin: FutureProtocol {
    let index: Int
    let state: Ref<[Int]>
    let expectation: XCTestExpectation

    mutating func poll(_ context: inout Context) -> Poll<Void> {
        if index < state.value.endIndex - 1 {
            let diff = state.value[index] - state.value[index + 1]
            XCTAssertLessThanOrEqual(diff.magnitude, 1)
            if state.value[index] >= 50 {
                expectation.fulfill()
                return .ready(DONE)
            }
        }
        state.value[index] += 1
        if state.value[index] >= 100 {
            expectation.fulfill()
            return .ready(DONE)
        }
        return context.yield()
    }
}

private func _testFairness<E: ExecutorProtocol>(
    _ testCase: XCTestCase,
    _ executor: E,
    _ cont: () -> Void
) throws {
    let count = 10
    let state = Ref(Array(repeating: 0, count: count))
    try testCase.expect(count: count, timeout: 5) { exp in
        for i in 0..<count {
            let result = executor.trySubmit(
                Spin(index: i, state: state, expectation: exp[i])
            )
            try result.get()
        }
        cont()
    }
}

final class SerialQueueExecutorTests: XCTestCase {
    func testFairness() throws {
        let queue = DispatchQueue(label: "tests.serial")
        let executor = QueueExecutor(targetQueue: queue)
        executor.suspend()
        try _testFairness(self, executor) {
            executor.resume()
        }
    }
}

final class ConcurrentQueueExecutorTests: XCTestCase {
    func testFairness() throws {
        let queue = DispatchQueue(label: "tests.concurrent", attributes: .concurrent)
        let executor = QueueExecutor(targetQueue: queue)
        executor.suspend()
        try _testFairness(self, executor) {
            executor.resume()
        }
    }
}

final class RunLoopExecutorExecutorTests: XCTestCase {
    func testFairness() throws {
        try _testFairness(self, RunLoopExecutor.current) {}
    }
}

final class ThreadExecutorTests: XCTestCase {
    func testFairness() throws {
        let executor = ThreadExecutor.current
        try _testFairness(self, executor) {
            XCTAssert(executor.run())
        }
    }

    func testRunNested() throws {
        var count = 0
        let executor = ThreadExecutor.current
        try executor.submit(lazy {
            try! executor.submit(lazy { // swiftlint:disable:this force_try
                count += 1
                return DONE
            })
            return DONE
        })
        XCTAssert(executor.run())
        XCTAssertEqual(count, 1)
    }

    func testRunMany() throws {
        let ITERATIONS = 200
        var count = 0
        let executor = ThreadExecutor.current
        for _ in 0..<ITERATIONS {
            try executor.submit(lazy {
                count += 1
                return DONE
            })
        }
        XCTAssert(executor.run())
        XCTAssertEqual(count, ITERATIONS)
    }

    func testRunUntil() {
        var count = 0
        let executor = ThreadExecutor.current
        var f = delayed(by: 1) { () -> Void in
            count += 1
            return DONE
        }
        executor.run(until: &f)
        XCTAssertEqual(count, 1)
    }

    func testRunUntilIgnoresSpawned() throws {
        let executor = ThreadExecutor()
        try executor.submit(pending())
        var f = lazy { DONE }
        executor.run(until: &f)
    }

    func testSpin() {
        let ITERATIONS = 100_000
        var count = 0

        let queue1 = DispatchQueue(label: "test-thread-executor-1")
        let queue2 = DispatchQueue(label: "test-thread-executor-2")
        let group = DispatchGroup()
        do {
            let (tx, rx) = Channel.makeUnbuffered(itemType: Int.self).split()
            queue1.async(group: group) {
                var f = (0..<ITERATIONS).makeStream()
                    .forward(to: tx)
                    .ignoreOutput()
                f.wait()
            }
            queue2.async(group: group) {
                var f = rx.makeStream()
                    .map { count += $0 }
                    .ignoreOutput()
                f.wait()
            }
        }
        group.wait()
        XCTAssertEqual(count, (0..<ITERATIONS).reduce(into: 0, +=))
    }
}
