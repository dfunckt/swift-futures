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

    func testSendReceive() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.tryFlush(), true)

        XCTAssertSuccess(tx.trySend(1), true)
        XCTAssertSuccess(tx.trySend(2), false)
        XCTAssertSuccess(rx.tryRecv(), 1)
        XCTAssertSuccess(tx.tryFlush(), true)

        XCTAssertSuccess(tx.trySend(2), true)
        XCTAssertSuccess(tx.tryFlush(), false)

        XCTAssertSuccess(rx.tryRecv(), 2)
        XCTAssertSuccess(rx.tryRecv(), nil)

        tx.cancel()
        XCTAssertFailure(tx.trySend(3), .cancelled)
        XCTAssertFailure(tx.tryFlush(), .cancelled)
    }

    func testSendReceiveAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let tx = tx.makeSink()
            let rx = rx.makeStream()

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

    func testSenderClose() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.trySend(1), true)
        tx.cancel()

        XCTAssertFailure(tx.trySend(2), .cancelled)
        XCTAssertSuccess(rx.tryRecv(), 1)
        XCTAssertFailure(rx.tryRecv(), .cancelled)
    }

    func testSenderCloseAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let tx = tx.makeSink()
            let rx = rx.makeStream()

            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertReady(tx.pollClose(&cx))

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), 1)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }

    func testReceiverClose() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.trySend(1), true)
        XCTAssertSuccess(rx.tryRecv(), 1)
        rx.cancel()

        XCTAssertFailure(tx.trySend(2), .cancelled)
        XCTAssertFailure(rx.tryRecv(), .cancelled)
    }

    func testReceiverCloseAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let tx = tx.makeSink()
            let rx = rx.makeStream()

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

    func testSendReceive() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.tryFlush(), true)

        XCTAssertSuccess(tx.trySend(1), true)
        XCTAssertSuccess(tx.trySend(2), true)
        if !C.Buffer.isPassthrough {
            XCTAssertSuccess(rx.tryRecv(), 1)
        }
        XCTAssertSuccess(rx.tryRecv(), 2)
        XCTAssertSuccess(tx.tryFlush(), true)

        XCTAssertSuccess(tx.trySend(3), true)
        XCTAssertSuccess(tx.tryFlush(), false)

        XCTAssertSuccess(rx.tryRecv(), 3)
        XCTAssertSuccess(rx.tryRecv(), nil)

        tx.cancel()
        XCTAssertFailure(tx.trySend(4), .cancelled)
        XCTAssertFailure(tx.tryFlush(), .cancelled)
    }

    func testSendReceiveAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let sink = tx.makeSink()
            let stream = rx.makeStream()

            XCTAssertReady(sink.pollFlush(&cx))

            XCTAssertReady(sink.pollSend(&cx, 1))
            XCTAssertReady(sink.pollSend(&cx, 2))
            if !C.Buffer.isPassthrough {
                XCTAssertEqual(stream.pollNext(&cx), 1)
            }
            XCTAssertEqual(stream.pollNext(&cx), 2)
            XCTAssertReady(sink.pollFlush(&cx))

            XCTAssertReady(sink.pollSend(&cx, 3))
            XCTAssertPending(sink.pollFlush(&cx))

            XCTAssertEqual(stream.pollNext(&cx), 3)
            XCTAssertPending(stream.pollNext(&cx))

            XCTAssertReady(sink.pollClose(&cx))
            XCTAssertFailure(sink.pollSend(&cx, 4), .closed)
            XCTAssertFailure(sink.pollFlush(&cx), .closed)

            return .ready(())
        }
    }

    func testSenderClose() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.trySend(1), true)
        tx.cancel()

        XCTAssertFailure(tx.trySend(2), .cancelled)
        XCTAssertSuccess(rx.tryRecv(), 1)
        XCTAssertFailure(rx.tryRecv(), .cancelled)
    }

    func testSenderCloseAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let tx = tx.makeSink()
            let rx = rx.makeStream()

            XCTAssertReady(tx.pollSend(&cx, 1))
            XCTAssertReady(tx.pollClose(&cx))

            XCTAssertFailure(tx.pollSend(&cx, 2), .closed)
            XCTAssertEqual(rx.pollNext(&cx), 1)
            XCTAssertEqual(rx.pollNext(&cx), nil) // swiftlint:disable:this xct_specific_matcher

            return .ready(())
        }
    }

    func testReceiverClose() {
        let (tx, rx) = makeChannel().split()

        XCTAssertSuccess(tx.trySend(1), true)
        XCTAssertSuccess(rx.tryRecv(), 1)
        rx.cancel()

        XCTAssertFailure(tx.trySend(2), .cancelled)
        XCTAssertFailure(rx.tryRecv(), .cancelled)
    }

    func testReceiverCloseAsync(_ testcase: XCTestCase) {
        let (tx, rx) = makeChannel().split()
        testcase.poll { cx in
            let tx = tx.makeSink()
            let rx = rx.makeStream()

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

    func testSPSC() {
        let executor = ThreadExecutor()
        var sum = 0

        let isPassthrough: Bool

        do {
            let (tx, rx) = makeChannel().split()
            isPassthrough = C.Buffer.isPassthrough
            executor.submit(
                rx.makeStream().map { sum += $0 }
            )
            let values = Stream.sequence(0..<SPSC_ITERATIONS)
            executor.submit(values.forward(to: tx).assertNoError())
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
            let (tx, rx) = makeChannel().split()
            executor.submit(
                rx.makeStream()
                    .map { sum += $0 }
                    .handleEvents(complete: {
                        exp[0].fulfill()
                    })
            )
            let values = Stream.sequence(0..<SPSC_ITERATIONS)
            values.forward(to: tx).assertNoError().wait()
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

    func testSPMC() {
        let executor = ThreadExecutor()
        var sum = 0

        let isPassthrough: Bool

        do {
            let (tx, rx) = makeChannel().split()
            isPassthrough = C.Buffer.isPassthrough
            let multicast = rx.makeStream().multicast()

            for _ in 0..<SPMC_RECEIVER_COUNT {
                executor.submit(
                    multicast.makeStream().map { sum += $0 }
                )
            }
            let values = Stream.sequence(0..<SPMC_ITERATIONS)
            executor.submit(values.forward(to: tx).assertNoError())
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
            let (tx, rx) = makeChannel().split()
            let multicast = rx.makeStream().share()

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
            values.forward(to: tx).assertNoError().wait()
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

    func testMPSC() {
        let executor = ThreadExecutor()

        let rx: C.Receiver = {
            let (tx, rx) = makeChannel().split()
            let values = Stream.sequence(0..<MPSC_ITERATIONS)

            for _ in 0..<MPSC_SENDER_COUNT {
                executor.submit(
                    values.forward(to: tx, close: false).assertNoError()
                )
            }

            return rx
        }()

        var sum = 0
        executor.submit(
            rx.makeStream().map { sum += $0 }
        )

        XCTAssert(executor.run())
        XCTAssertEqual(sum, MPSC_EXPECTED)
    }

    func testMPSCThreaded() {
        let executors = (0..<CPU_COUNT).map {
            QueueExecutor(label: "test-\($0)")
        }

        var tasks = [Task<Void>]()
        tasks.reserveCapacity(MPSC_SENDER_COUNT)

        let rx: C.Receiver = {
            let (tx, rx) = makeChannel().split()
            let values = Stream.sequence(0..<MPSC_ITERATIONS)

            for i in 0..<MPSC_SENDER_COUNT {
                tasks.append(executors[i % CPU_COUNT].spawn(
                    values.forward(to: tx, close: false).assertNoError()
                ))
            }

            return rx
        }()

        var sum = 0

        rx.makeStream()
            .map { sum += $0 }
            .ignoreOutput()
            .join(Future.joinAll(tasks))
            .ignoreOutput()
            .wait()

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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() { spmcTester.testSPMC() }
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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() { spmcTester.testSPMC() }
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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() { spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
    func testMPSC() { mpscTester.testMPSC() }
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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPMC() { spmcTester.testSPMC() }
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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() { spmcTester.testSPMC() }
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

    func testSendReceive() { tester.testSendReceive() }
    func testSendReceiveAsync() { tester.testSendReceiveAsync(self) }
    func testSenderClose() { tester.testSenderClose() }
    func testSenderCloseAsync() { tester.testSenderCloseAsync(self) }
    func testReceiverClose() { tester.testReceiverClose() }
    func testReceiverCloseAsync() { tester.testReceiverCloseAsync(self) }
    func testSPSC() { spscTester.testSPSC() }
    func testSPSCThreaded() { spscTester.testSPSCThreaded(self) }
    func testSPMC() { spmcTester.testSPMC() }
    func testSPMCThreaded() { spmcTester.testSPMCThreaded(self) }
    func testMPSC() { mpscTester.testMPSC() }
    func testMPSCThreaded() { mpscTester.testMPSCThreaded() }
}
