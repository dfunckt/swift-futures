//
//  ChannelTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesSync
import FuturesTestSupport
import XCTest

private let SPMC_RECEIVER_COUNT = 100
private let SPMC_ITERATIONS = 100
private let SPMC_EXPECTED = (0..<SPMC_ITERATIONS).reduce(into: 0, +=) * SPMC_RECEIVER_COUNT
private let SPMC_EXPECTED_PASSTHROUGH = (SPMC_ITERATIONS - 1) * SPMC_RECEIVER_COUNT

private let MPSC_SENDER_COUNT = SPMC_RECEIVER_COUNT
private let MPSC_ITERATIONS = SPMC_ITERATIONS
private let MPSC_EXPECTED = (0..<MPSC_ITERATIONS).reduce(into: 0, +=) * MPSC_SENDER_COUNT

private let SPSC_ITERATIONS = SPMC_ITERATIONS * SPMC_RECEIVER_COUNT
private let SPSC_EXPECTED = (0..<SPSC_ITERATIONS).reduce(into: 0, +=)
private let SPSC_EXPECTED_PASSTHROUGH = SPSC_ITERATIONS - 1

private final class BoundedChannelTester<C: ChannelProtocol> where C.Item == Int {
    typealias Constructor = () -> Channel.Pipe<C>

    let makeChannel: Constructor

    init(constructor: @escaping Constructor) {
        makeChannel = constructor
    }

    func testSendReceive(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollFlush(&cx))

            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertPending(tx.pollSend(&cx, 2))
            XCTAssertEqual(rx.pollNext(&cx), 1)
            XCTAssertReady(tx.pollFlush(&cx))

            XCTAssertReady(tx.pollSend(&cx, 2))
            XCTAssertPending(tx.pollFlush(&cx))

            XCTAssertEqual(rx.pollNext(&cx), 2)
            XCTAssertPending(rx.pollNext(&cx))

            XCTAssertReady(tx.pollClose(&cx))
            XCTAssertFailure(tx.pollSend(&cx, 3), .closed)
            XCTAssertFailure(tx.pollFlush(&cx), .closed)

            return .ready(())
        }
    }

    func testSenderClose(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertReady(tx.pollClose(&cx))

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), 1)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }

    func testReceiverClose(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertEqual(rx.pollNext(&cx), 1)
            rx.cancel()

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }
}

private final class UnboundedChannelTester<C: UnboundedChannelProtocol> where C.Item == Int {
    typealias Constructor = () -> Channel.Pipe<C>

    let makeChannel: Constructor

    init(constructor: @escaping Constructor) {
        makeChannel = constructor
    }

    func testSendReceive(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollFlush(&cx))

            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertReady(tx.pollSend(&cx, 2))
            if !C.Buffer.isPassthrough {
                XCTAssertEqual(rx.pollNext(&cx), 1)
            }
            XCTAssertEqual(rx.pollNext(&cx), 2)
            XCTAssertReady(tx.pollFlush(&cx))

            XCTAssertReady(tx.pollSend(&cx, 3))
            XCTAssertPending(tx.pollFlush(&cx))

            XCTAssertEqual(rx.pollNext(&cx), 3)
            XCTAssertPending(rx.pollNext(&cx))

            XCTAssertReady(tx.pollClose(&cx))
            XCTAssertFailure(tx.pollSend(&cx, 4), .closed)
            XCTAssertFailure(tx.pollFlush(&cx), .closed)

            return .ready(())
        }
    }

    func testSenderClose(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertReady(tx.pollClose(&cx))

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), 1)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }

    func testReceiverClose(_ testcase: XCTestCase) {
        let (rx, tx) = makeChannel().split()
        testcase.poll { cx in
            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertEqual(rx.pollNext(&cx), 1)
            rx.cancel()

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }
}

private final class SPSCChannelTester<C: ChannelProtocol> where C.Item == Int {
    typealias Constructor = () -> Channel.Pipe<C>

    let makeChannel: Constructor

    init(constructor: @escaping Constructor) {
        makeChannel = constructor
    }

    func testSPSC() throws {
        let executor = ThreadExecutor()
        var sum = 0

        let isPassthrough: Bool

        do {
            let (rx, tx) = makeChannel().split()
            isPassthrough = C.Buffer.isPassthrough
            try executor.submit(rx.map { sum += $0 })
            let values = Stream.sequence(0..<SPSC_ITERATIONS)
            try executor.submit(values.forward(to: tx).assertNoError())
            XCTAssert(executor.run())
        }

        if !isPassthrough {
            XCTAssertEqual(sum, SPSC_EXPECTED)
        } else {
            XCTAssertEqual(sum, SPSC_EXPECTED_PASSTHROUGH)
        }
    }

    func testSPSCThreaded(_ testcase: XCTestCase) {
        let executor = QueueExecutor.userInitiated
        var sum = 0

        testcase.expect(timeout: 60) { exp in
            let (rx, tx) = makeChannel().split()
            executor.submit(
                rx
                    .map { sum += $0 }
                    .handleEvents(complete: {
                        exp[0].fulfill()
                    })
            )
            let values = Stream.sequence(0..<SPSC_ITERATIONS)
            var f = values.forward(to: tx).assertNoError()
            f.wait()
        }

        XCTAssertEqual(sum, SPSC_EXPECTED)
    }
}

private final class SPMCChannelTester<C: ChannelProtocol> where C.Item == Int {
    typealias Constructor = () -> Channel.Pipe<C>

    let makeChannel: Constructor

    init(constructor: @escaping Constructor) {
        makeChannel = constructor
    }

    func testSPMC() throws {
        let executor = ThreadExecutor()
        var sum = 0

        let isPassthrough: Bool

        do {
            let (rx, tx) = makeChannel().split()
            isPassthrough = C.Buffer.isPassthrough
            let multicast = rx.multicast()

            for _ in 0..<SPMC_RECEIVER_COUNT {
                try executor.submit(
                    multicast.makeStream().map { sum += $0 }
                )
            }
            let values = Stream.sequence(0..<SPMC_ITERATIONS)
            try executor.submit(values.forward(to: tx).assertNoError())
            XCTAssert(executor.run())
        }

        if !isPassthrough {
            XCTAssertEqual(sum, SPMC_EXPECTED)
        } else {
            XCTAssertEqual(sum, SPMC_EXPECTED_PASSTHROUGH)
        }
    }

    func testSPMCThreaded(_ testcase: XCTestCase) {
        let executors = (0..<CPU_COUNT).map {
            QueueExecutor(label: "test-\($0)")
        }
        let sum = AtomicInt(0)

        testcase.expect(count: SPMC_RECEIVER_COUNT, timeout: 60, enforceOrder: false) { exp in
            let (rx, tx) = makeChannel().split()
            let multicast = rx.share()

            for i in 0..<SPMC_RECEIVER_COUNT {
                executors[i % CPU_COUNT].submit(
                    multicast.makeStream()
                        .map { sum.fetchAdd($0, order: .relaxed) }
                        .handleEvents(complete: {
                            exp[i].fulfill()
                        })
                )
            }
            let values = Stream.sequence(0..<SPMC_ITERATIONS)
            var f = values.forward(to: tx).assertNoError()
            f.wait()
        }

        XCTAssertEqual(sum.load(), SPMC_EXPECTED)
    }
}

private final class MPSCChannelTester<C: ChannelProtocol> where C.Item == Int {
    typealias Constructor = () -> Channel.Pipe<C>

    let makeChannel: Constructor

    init(constructor: @escaping Constructor) {
        makeChannel = constructor
    }

    func testMPSC() throws {
        let executor = ThreadExecutor()

        let rx: C.Receiver = try {
            let (rx, tx) = makeChannel().split()
            let values = Stream.sequence(0..<MPSC_ITERATIONS)

            for _ in 0..<MPSC_SENDER_COUNT {
                try executor.submit(
                    values.forward(to: tx, close: false).assertNoError()
                )
            }

            return rx
        }()

        var sum = 0
        try executor.submit(rx.map { sum += $0 })

        XCTAssert(executor.run())
        XCTAssertEqual(sum, MPSC_EXPECTED)
    }

    func testMPSCThreaded() {
        let executors = (0..<CPU_COUNT).map {
            QueueExecutor(label: "test-\($0)")
        }

        let rx: C.Receiver = {
            let (rx, tx) = makeChannel().split()
            let values = Stream.sequence(0..<MPSC_ITERATIONS)

            for i in 0..<MPSC_SENDER_COUNT {
                executors[i % CPU_COUNT].submit(
                    values.forward(to: tx, close: false).assertNoError()
                )
            }

            return rx
        }()

        var sum = 0

        var f = rx
            .map { sum += $0 }
            .ignoreOutput()
        f.wait()

        XCTAssertEqual(sum, MPSC_EXPECTED)
    }
}

// MARK: -

final class UnbufferedChannelTests: XCTestCase {
    private lazy var tester = BoundedChannelTester {
        Channel.makeUnbuffered()
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makeUnbuffered()
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makeUnbuffered()
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() throws { try spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
}

final class BufferedChannelTests: XCTestCase {
    private lazy var tester = BoundedChannelTester {
        Channel.makeBuffered(capacity: 1)
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makeBuffered(capacity: 1)
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makeBuffered(capacity: 1)
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() throws { try spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
}

final class SharedChannelTests: XCTestCase {
    private lazy var tester = BoundedChannelTester {
        Channel.makeShared(capacity: 1)
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makeShared(capacity: 1)
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makeShared(capacity: 1)
    }

    private lazy var mpscTester = MPSCChannelTester {
        Channel.makeShared(capacity: 1)
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() throws { try spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
    func testMPSC() throws { try mpscTester.testMPSC() }
    func testMPSCThreaded() { mpscTester.testMPSCThreaded() }
}

// MARK: -

final class PassthroughChannelTests: XCTestCase {
    private lazy var tester = UnboundedChannelTester {
        Channel.makePassthrough()
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makePassthrough()
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makePassthrough()
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPMC() throws { try spmcTester.testSPMC() }
}

final class BufferedUnboundedChannelTests: XCTestCase {
    private lazy var tester = UnboundedChannelTester {
        Channel.makeBuffered()
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makeBuffered()
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makeBuffered()
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() throws { try spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
}

final class SharedUnboundedChannelTests: XCTestCase {
    private lazy var tester = UnboundedChannelTester {
        Channel.makeShared()
    }

    private lazy var spscTester = SPSCChannelTester {
        Channel.makeShared()
    }

    private lazy var spmcTester = SPMCChannelTester {
        Channel.makeShared()
    }

    private lazy var mpscTester = MPSCChannelTester {
        Channel.makeShared()
    }

    func testSendReceive() { tester.testSendReceive(self) }
    func testSenderClose() { tester.testSenderClose(self) }
    func testReceiverClose() { tester.testReceiverClose(self) }

    func testSPSC() throws { try spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() throws { try spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
    func testMPSC() throws { try mpscTester.testMPSC() }
    func testMPSCThreaded() { mpscTester.testMPSCThreaded() }
}
