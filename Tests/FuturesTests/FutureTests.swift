//
//  FutureTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesTestSupport
import XCTest

final class FutureTests: XCTestCase {
    func testDeferred() {
        let f = Deferred<Int> {
            $0.resolve(42)
            return .empty
        }
        XCTAssertEqual(f.wait(), 42)
    }

    // MARK: -

    func testNever() {
        let f = Future.never(outputType: Void.self)
        let executor = ThreadExecutor()
        executor.submit(f)
        XCTAssertFalse(executor.run())
    }

    func testReady() {
        do {
            let f = Future.ready()
            XCTAssert(f.wait() == ())
        }
        do {
            let f = Future.ready(42)
            XCTAssertEqual(f.wait(), 42)
        }
    }

    func testLazy() {
        let f = Future.lazy {
            makeFuture(42)
        }
        XCTAssertEqual(f.wait(), 42)
    }

    // MARK: -

    func testMakeFuture() {
        let f = makeFuture(42).makeFuture()
        XCTAssertEqual(f.wait(), 42)
    }

    func testMakeStream() {
        var s = makeFuture(42).makeStream()
        XCTAssertEqual(s.next(), 42)
        XCTAssertNil(s.next())
    }

    func testMakeReference() {
        // FIXME: improve test
        // we need to check that f1 and f2 have indeed completed
        // but doing so would trap.
        let f1 = makeFuture(4).makeReference()
        let f2 = makeFuture(2).makeReference()
        let f = Future.join(f1, f2)
        XCTAssert(f.wait() == (4, 2))
    }

    func testWait() {
        let f = makeFuture(42)
        XCTAssertEqual(f.wait(), 42)
    }

    // TODO: testAssign()
    // TODO: testSink()
    // TODO: testAbort()

    func testPollOn() {
        let f = makeFuture(42)
            .poll(on: QueueExecutor.global)
            .assertNoError()
        XCTAssertEqual(f.wait(), 42)
    }

    // MARK: -

    func testEraseToAnyFuture() {
        let f = makeFuture(42).eraseToAnyFuture()
        XCTAssertEqual(f.wait(), 42)
    }

    // TODO: testMulticast()
    // TODO: testEraseToAnyMulticastFuture()
    // TODO: testShare()
    // TODO: testEraseToAnySharedFuture()

    // MARK: -

    func testMap() {
        let f = makeFuture(4).map {
            String($0) + "2"
        }
        XCTAssertEqual(f.wait(), "42")
    }

    func testMapKeyPath() {
        struct Data {
            let a, b, c: Int
        }
        let data: Data = .init(a: 0, b: 1, c: 2)
        do {
            let f = makeFuture(data).map(\.a)
            XCTAssertEqual(f.wait(), 0)
        }
        do {
            let f = makeFuture(data).map(\.a, \.b)
            XCTAssert(f.wait() == (0, 1))
        }
        do {
            let f = makeFuture(data).map(\.a, \.b, \.c)
            XCTAssert(f.wait() == (0, 1, 2))
        }
    }

    func testFlatMap() {
        let f = makeFuture(4).flatMap {
            makeFuture(String($0) + "2")
        }
        XCTAssertEqual(f.wait(), "42")
    }

    func testThen() {
        let f = makeFuture(14).then(on: QueueExecutor.global) { value in
            makeFuture(assertOnQueueExecutor(.global)).map {
                value * 3
            }
        }
        XCTAssertEqual(f.wait(), .success(42))
    }

    func testPeek() {
        expect(count: 1) { exp in
            let f = makeFuture(42).peek { _ in
                exp[0].fulfill()
            }
            XCTAssertEqual(f.wait(), 42)
        }
    }

    func testReplaceNil() {
        do {
            let f = makeFuture(Int?.some(5)).replaceNil(with: 42)
            XCTAssertEqual(f.wait(), 5)
        }
        do {
            let f = makeFuture(Int?.none).replaceNil(with: 42)
            XCTAssertEqual(f.wait(), 42)
        }
    }

    func testReplaceOutput() {
        let f = makeFuture(5).replaceOutput(with: 42)
        XCTAssertEqual(f.wait(), 42)
    }

    func testIgnoreOutput() {
        let f = makeFuture(42).ignoreOutput()
        XCTAssert(f.wait() == ())
    }

    func testMatchOptional() {
        do {
            let f = makeFuture(Int?.some(42)).match(
                some: String.init,
                none: { "NaN" }
            )
            XCTAssertEqual(f.wait(), "42")
        }
        do {
            let f = makeFuture(Int?.none).match(
                some: String.init,
                none: { "NaN" }
            )
            XCTAssertEqual(f.wait(), "NaN")
        }
    }

    func testMatchEither() {
        func transform(_ value: Int) -> Either<Int, Float> {
            if value == 42 {
                return .left(value)
            } else {
                return .right(.init(value))
            }
        }
        do {
            let f = makeFuture(42).map(transform).match(
                left: String.init,
                right: String.init(describing:)
            )
            XCTAssertEqual(f.wait(), "42")
        }
        do {
            let f = makeFuture(5).map(transform).match(
                left: String.init,
                right: String.init(describing:)
            )
            XCTAssertEqual(f.wait(), "5.0")
        }
    }

    // MARK: -

    func testJoinAll() {
        do {
            let f = Future.joinAll([
                makeFuture(1),
                makeFuture(2),
                makeFuture(3),
            ])
            XCTAssertEqual(f.wait(), [1, 2, 3])
        }
        do {
            let f = Future.joinAll(
                makeFuture(1),
                makeFuture(2),
                makeFuture(3)
            )
            XCTAssertEqual(f.wait(), [1, 2, 3])
        }
    }

    func testJoin() {
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let f = Future.join(a, b)
            XCTAssert(f.wait() == (1, "A"))
        }
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let c = makeFuture("X")
            let f = Future.join(a, b, c)
            XCTAssert(f.wait() == (1, "A", "X"))
        }
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let c = makeFuture("X")
            let d = makeFuture(5)
            let f = Future.join(a, b, c, d)
            XCTAssert(f.wait() == (1, "A", "X", 5))
        }
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let f = a.join(b)
            XCTAssert(f.wait() == (1, "A"))
        }
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let c = makeFuture("X")
            let f = a.join(b, c)
            XCTAssert(f.wait() == (1, "A", "X"))
        }
        do {
            let a = makeFuture(1)
            let b = makeFuture("A")
            let c = makeFuture("X")
            let d = makeFuture(5)
            let f = a.join(b, c, d)
            XCTAssert(f.wait() == (1, "A", "X", 5))
        }
    }

    func testSelectAny() {
        do {
            let f = Future.selectAny([
                Future.ready(1),
                Future.ready(2),
                Future.ready(3),
            ])
            XCTAssertEqual(f.wait(), 1)
        }
        do {
            let f = Future.selectAny(
                Future.ready(1),
                Future.ready(2),
                Future.ready(3)
            )
            XCTAssertEqual(f.wait(), 1)
        }
    }

    func testSelect() {
        do {
            let a = Future.ready(1)
            let b = Future.ready("A")
            let f = Future.select(a, b)
            XCTAssertEqual(f.wait(), .left(1))
        }
        do {
            let a = Future.ready(1)
            let b = Future.ready("A")
            let f = a.select(b)
            XCTAssertEqual(f.wait(), .left(1))
        }
    }

    // MARK: -

    func testFlatten() {
        let a = makeFuture(4).map {
            makeFuture(String($0) + "2")
        }
        let f = a.flatten()
        XCTAssertEqual(f.wait(), "42")
    }

    // MARK: -

    enum UltimateQuestionError: Error, Equatable {
        case wrongAnswer
    }

    func validateAnswer(_ answer: Int) throws -> Int {
        guard answer == 42 else {
            throw UltimateQuestionError.wrongAnswer
        }
        return answer
    }

    // MARK: -

    func testTryLazy() {
        let f = Future.tryLazy {
            makeFuture(42)
        }
        XCTAssertSuccess(f.wait(), 42)
    }

    func testTryMap() {
        do {
            let f = makeFuture(42).tryMap(validateAnswer)
            XCTAssertSuccess(f.wait(), 42)
        }
        do {
            let f = makeFuture(5).tryMap(validateAnswer)
            XCTAssertFailure(f.wait(), UltimateQuestionError.wrongAnswer)
        }
    }

    func testSetFailureType() {
        do {
            let f = makeFuture(42).setFailureType(to: UltimateQuestionError.self)
            XCTAssertSuccess(f.wait(), 42)
        }
        do {
            let a = makeFuture(42).map(Result<Int, Never>.success)
            let f = a.setFailureType(to: UltimateQuestionError.self)
            XCTAssertSuccess(f.wait(), 42)
        }
    }

    // MARK: -

    func testMatchResult() {
        do {
            let a = makeFuture(5).tryMap(validateAnswer)
            let f = a.match(
                success: String.init,
                failure: String.init(describing:)
            )
            XCTAssertEqual(f.wait(), "wrongAnswer")
        }
        do {
            let a = makeFuture(42).tryMap(validateAnswer)
            let f = a.match(
                success: String.init,
                failure: String.init(describing:)
            )
            XCTAssertEqual(f.wait(), "42")
        }
    }

    func testMapValue() {
        do {
            let f = makeFuture(5).tryMap(validateAnswer).mapValue {
                $0 + 1
            }
            XCTAssertFailure(f.wait(), UltimateQuestionError.wrongAnswer)
        }
        do {
            let f = makeFuture(42).tryMap(validateAnswer).mapValue {
                $0 + 1
            }
            XCTAssertSuccess(f.wait(), 43)
        }
    }

    func testMapError() {
        struct WrappedError: Error {
            let error: Error
        }
        do {
            let f = makeFuture(5).tryMap(validateAnswer).mapError {
                WrappedError(error: $0)
            }
            XCTAssertFailure(f.wait())
        }
        do {
            let f = makeFuture(42).tryMap(validateAnswer).mapError {
                WrappedError(error: $0)
            }
            XCTAssertSuccess(f.wait(), 42)
        }
    }

    func testFlattenResult() {
        do {
            let a = makeFuture(5)
                .tryMap(validateAnswer)
                .mapValue { Result<Int, Error>.success($0) }
            let f = a.flattenResult()
            XCTAssertFailure(f.wait(), UltimateQuestionError.wrongAnswer)
        }
        do {
            let a = makeFuture(42)
                .tryMap(validateAnswer)
                .mapValue { Result<Int, Error>.success($0) }
            let f = a.flattenResult()
            XCTAssertSuccess(f.wait(), 42)
        }
    }

    // MARK: -

    // TODO: testAssertNoError()

    func testReplaceError() {
        let a = makeFuture(5).tryMap(validateAnswer)
        let f = a.replaceError(with: 42)
        XCTAssertEqual(f.wait(), 42)
    }

    func testCatchError() {
        let f = makeFuture(5).tryMap(validateAnswer).catchError { _ in
            makeFuture(42)
        }
        XCTAssertEqual(f.wait(), 42)
    }

    // MARK: -

    // TODO: testDelay()
    // TODO: testTimeout()

    // MARK: -

    // TODO: testDecode()
    // TODO: testEncode()

    // MARK: -

    // TODO: testBreakpoint()
    // TODO: testHandleEvents()
    // TODO: testPrint()
    // TODO: testBreakpointOnError()
}
