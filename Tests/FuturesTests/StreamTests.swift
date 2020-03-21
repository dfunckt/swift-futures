//
//  StreamTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

// swiftlint:disable force_unwrapping

import Futures
import FuturesSync
import FuturesTestSupport
import XCTest

final class StreamTests: XCTestCase {
    func testNever() throws {
        let s = Stream.never(outputType: Void.self)
        let executor = ThreadExecutor()
        try executor.submit(s)
        XCTAssertFalse(executor.run())
    }

    func testEmpty() {
        var s = Stream.empty(outputType: Void.self)
        XCTAssertNil(s.next())
    }

    func testOptional() {
        do {
            let someInt: Int? = 42
            var s = Stream.optional(someInt)
            XCTAssertEqual(s.next(), 42)
            XCTAssertNil(s.next())
        }
        do {
            let noInt: Int? = nil
            var s = Stream.optional(noInt)
            XCTAssertNil(s.next())
        }
    }

    func testJust() {
        var s = Stream.just(42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertNil(s.next())
    }

    func testRepeat() {
        var s = Stream.repeat(42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 42)
    }

    func testSequence() {
        var s = Stream.sequence(0..<3)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testGenerate() {
        var s = Stream.generate(first: 1) {
            $0 < 3 ? $0 + 1 : nil
        }
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertNil(s.next())
    }

    func testUnfold() {
        var s = Stream.unfold(initial: 1) {
            $0 < 3 ? Future.ready($0 + 1) : nil
        }
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertNil(s.next())
    }

    func testLazy() {
        var s = Stream.lazy {
            Stream.sequence(0..<3)
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    // MARK: -

    func testMakeFuture() {
        do {
            var output: Int?
            var s = makeStream(0..<3)

            (output, s) = s.makeFuture().wait()
            XCTAssertEqual(output, 0)

            (output, s) = s.makeFuture().wait()
            XCTAssertEqual(output, 1)

            (output, s) = s.makeFuture().wait()
            XCTAssertEqual(output, 2)

            (output, s) = s.makeFuture().wait()
            XCTAssertNil(output)
        }
        do {
            var s = makeStream(0..<3)

            XCTAssertEqual(s.makeFuture().wait().0, 0)
            XCTAssertEqual(s.makeFuture().wait().0, 0)
            XCTAssertEqual(s.next(), 0)

            XCTAssertEqual(s.makeFuture().wait().0, 1)
            XCTAssertEqual(s.makeFuture().wait().0, 1)
            XCTAssertEqual(s.next(), 1)

            XCTAssertEqual(s.makeFuture().wait().0, 2)
            XCTAssertEqual(s.makeFuture().wait().0, 2)
            XCTAssertEqual(s.next(), 2)

            XCTAssertNil(s.makeFuture().wait().0)
            XCTAssertNil(s.makeFuture().wait().0)
            XCTAssertNil(s.next())
        }
    }

    func testMakeStream() {
        var s = makeStream(0..<3).makeStream()
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testMakeReference() {
        var s1 = Stream.sequence(0..<3).makeReference()
        var s2 = Stream.sequence(3..<6).makeReference()
        var s = Stream.join(s1, s2)
        XCTAssert(s.next()! == (0, 3))
        XCTAssertEqual(s1.next(), 1)
        XCTAssertEqual(s2.next(), 4)
        XCTAssert(s.next()! == (2, 5))
        XCTAssertNil(s.next())
    }

    func testNext() {
        do {
            var s = Stream.sequence(0..<3)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            let executor = ThreadExecutor.current
            var s = Stream.sequence(0..<3)
            XCTAssertEqual(s.next(on: executor), 0)
            XCTAssertEqual(s.next(on: executor), 1)
            XCTAssertEqual(s.next(on: executor), 2)
            XCTAssertNil(s.next(on: executor))
        }
    }

    func testForward() {
        let sink = Sink.collect(itemType: Int.self)
        let f = makeStream(0..<3).forward(to: sink)
        f.ignoreOutput().wait()
        XCTAssertEqual(sink.elements, [0, 1, 2])
    }

    // TODO: testAssign()
    // TODO: testSink()
    // TODO: testAbort()

    func testPollOn() {
        var s = makeStream(0..<3)
            .poll(on: QueueExecutor.global)
            .assertNoError()
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    // TODO: testYield()

    // MARK: -

    func testEraseToAnyStream() {
        do {
            // AnyStream.init(pollNext:)
            var iter = (0..<3).makeIterator()
            var s = AnyStream { _ in
                .ready(iter.next())
            }
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            // AnyStream.init(stream:)
            var s = makeStream(0..<3).eraseToAnyStream()
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            // AnyStream.init(stream:)
            var s = makeStream(0..<3).eraseToAnyStream().eraseToAnyStream()
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
    }

    func _testMulticastBasic<U: StreamConvertible>(_ constructor: (TestStream<Range<Int>>) -> U) where U.StreamType: Cancellable, U.StreamType.Output == Int {
        do {
            let m = constructor(makeStream(0..<3))
            var s = m.makeStream()
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }

        do {
            let m = constructor(makeStream(0..<3))
            var s1 = m.makeStream()
            var s2 = m.makeStream()
            XCTAssertEqual(s1.next(), 0)
            XCTAssertEqual(s2.next(), 0)
            XCTAssertEqual(s1.next(), 1)
            XCTAssertEqual(s2.next(), 1)
            XCTAssertEqual(s1.next(), 2)
            XCTAssertEqual(s2.next(), 2)
            XCTAssertNil(s1.next())
            XCTAssertNil(s2.next())
        }

        do {
            let m = constructor(makeStream(0..<3))
            var s1 = m.makeStream()
            XCTAssertEqual(s1.next(), 0)
            var s2 = m.makeStream()
            XCTAssertEqual(s1.next(), 1)
            var s3 = m.makeStream()
            XCTAssertEqual(s2.next(), 1)
            XCTAssertEqual(s1.next(), 2)
            s2.cancel()
            XCTAssertEqual(s3.next(), 2)
            XCTAssertNil(s3.next())
            XCTAssertNil(s1.next())
        }

        do {
            let m = constructor(makeStream(0..<3))
            let s1 = m.makeStream()
            let s2 = m.makeStream()
            let s3 = m.makeStream()
            let f = Stream.merge(s1, s2, s3).collect()
            XCTAssertEqual(f.wait(), [0, 0, 0, 1, 1, 1, 2, 2, 2])
        }

        do {
            let m = constructor(makeStream(0..<3))
            let s1 = m.makeStream().prefix(2).makeReference()
            let s2 = m.makeStream().prefix(1).makeReference()
            let s3 = m.makeStream().prefix(0).makeReference()
            let f = Stream.merge(s1, s2, s3).collect()
            XCTAssertEqual(f.wait(), [0, 0, 1])
        }
    }

    typealias S = Futures.Stream._Private.ForEach<TestStream<Range<Int>>>

    func _testMulticast<U: StreamConvertible>(_ constructor: (S) -> U) throws where U.StreamType.Output == S.Output {
        // TODO: test replay strategies
        let iterations = 1_000
        var counter0 = 0
        var counter1 = 0
        var counter2 = 0

        let stream = makeStream(0..<iterations).forEach { counter0 += $0 }

        let multicast = constructor(stream)
        let stream1 = multicast.makeStream().map { counter1 += $0 }
        let stream2 = multicast.makeStream().map { counter2 += $0 }

        try ThreadExecutor.current.submit(stream1)
        try ThreadExecutor.current.submit(stream2)
        ThreadExecutor.current.wait()

        let expected = (0..<iterations).reduce(into: 0, +=)
        XCTAssertEqual(counter0, expected)
        XCTAssertEqual(counter1, expected)
        XCTAssertEqual(counter2, expected)
    }

    func _testShare<U: StreamConvertible>(_ constructor: (S) -> U) throws where U.StreamType.Output == S.Output {
        // TODO: test replay strategies
        let iterations = 1_000
        var counter0 = 0
        var counter1 = 0
        var counter2 = 0

        let stream = makeStream(0..<iterations).forEach { counter0 += $0 }

        let shared = constructor(stream)
        let stream1 = shared.makeStream().map { counter1 += $0 }
        let stream2 = shared.makeStream().map { counter2 += $0 }

        let task1 = QueueExecutor(label: "queue 1").spawn(stream1)
        let task2 = QueueExecutor(label: "queue 2").spawn(stream2)

        try ThreadExecutor.current.submit(task1.assertNoError())
        try ThreadExecutor.current.submit(task2.assertNoError())
        ThreadExecutor.current.wait()

        let expected = (0..<iterations).reduce(into: 0, +=)
        XCTAssertEqual(counter0, expected)
        XCTAssertEqual(counter1, expected)
        XCTAssertEqual(counter2, expected)
    }

    func testMulticast() throws {
        _testMulticastBasic { $0.multicast() }
        try _testMulticast { $0.multicast() }
    }

    func testEraseToAnyMulticastStream() throws {
        try _testMulticast { $0.eraseToAnyMulticastStream() }
    }

    func testShare() throws {
        _testMulticastBasic { $0.share() }
        try _testMulticast { $0.share() }
        try _testShare { $0.share() }
    }

    func testEraseToAnySharedStream() throws {
        try _testShare { $0.eraseToAnySharedStream() }
    }

    // MARK: -

    func testMap() {
        var s = makeStream(0..<3).map {
            $0 + 1
        }
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertNil(s.next())
    }

    func testMapKeyPath() {
        struct Data {
            let a, b, c: Int
        }
        let data: [Data] = [
            .init(a: 0, b: 1, c: 2),
            .init(a: 3, b: 4, c: 5),
            .init(a: 6, b: 7, c: 8),
        ]
        do {
            var s = makeStream(data).map(\.a)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(data).map(\.a, \.b)
            XCTAssert(s.next()! == (0, 1))
            XCTAssert(s.next()! == (3, 4))
            XCTAssert(s.next()! == (6, 7))
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(data).map(\.a, \.b, \.c)
            XCTAssert(s.next()! == (0, 1, 2))
            XCTAssert(s.next()! == (3, 4, 5))
            XCTAssert(s.next()! == (6, 7, 8))
            XCTAssertNil(s.next())
        }
    }

    func testFlatMap() {
        var s = makeStream(0..<3).flatMap {
            makeStream(0...($0 + 1))
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertNil(s.next())
    }

    // TODO: testThen()

    func testScan() {
        var s = makeStream(0..<3).scan(0) {
            $0 + $1
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 3)
        XCTAssertNil(s.next())
    }

    func testReplaceNil() {
        var s = makeStream([0, nil, 2]).replaceNil(with: 1)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testMatchOptional() {
        var s = makeStream([0, nil, 2]).match(
            some: String.init,
            none: { "NaN" }
        )
        XCTAssertEqual(s.next(), "0")
        XCTAssertEqual(s.next(), "NaN")
        XCTAssertEqual(s.next(), "2")
        XCTAssertNil(s.next())
    }

    func testMatchEither() {
        func transform(_ value: Int) -> Either<Int, Float> {
            return value == 0 ? .left(value) : .right(.init(value))
        }
        var s = makeStream(0..<3).map(transform).match(
            left: String.init,
            right: String.init(describing:)
        )
        XCTAssertEqual(s.next(), "0")
        XCTAssertEqual(s.next(), "1.0")
        XCTAssertEqual(s.next(), "2.0")
        XCTAssertNil(s.next())
    }

    // MARK: -

    func testFilter() {
        var s = makeStream(0..<3).filter {
            $0 > 0
        }
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testCompactMap() {
        var s = makeStream(0..<3).compactMap {
            $0 > 0 ? $0 * 2 : nil
        }
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 4)
        XCTAssertNil(s.next())
    }

    func testReplaceEmpty() {
        var s = Stream.empty().replaceEmpty(with: 42)
        XCTAssertEqual(s.next(), 42)
        XCTAssertNil(s.next())
    }

    func testRemoveDuplicates() {
        do {
            let data = [
                (1, "A"),
                (2, "B"),
                (3, "B"),
                (4, "C"),
            ]
            var s = makeStream(data).removeDuplicates {
                $0.1 == $1.1
            }
            XCTAssert(s.next()! == (1, "A"))
            XCTAssert(s.next()! == (2, "B"))
            XCTAssert(s.next()! == (4, "C"))
            XCTAssertNil(s.next())
        }

        do {
            var s = makeStream([1, 2, 2, 2, 3]).removeDuplicates()
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 3)
            XCTAssertNil(s.next())
        }
    }

    // MARK: -

    func testCollect() {
        let f = makeStream(0..<3).collect()
        XCTAssertEqual(f.wait(), [0, 1, 2])
    }

    func testReplaceOutput() {
        let f = makeStream(0..<3).replaceOutput(with: 42)
        XCTAssertEqual(f.wait(), 42)
    }

    func testIgnoreOutput() {
        let f = makeStream(0..<3).ignoreOutput()
        XCTAssert(f.wait() == ())
    }

    func testCount() {
        let f = makeStream(0..<3).count()
        XCTAssertEqual(f.wait(), 3)
    }

    func testReduce() {
        let f = makeStream(0..<3).reduce(0) {
            $0 + $1
        }
        XCTAssertEqual(f.wait(), 3)
    }

    func testReduceInto() {
        let f = makeStream(0..<3).reduce(into: []) {
            $0.append($1 + 1)
        }
        XCTAssertEqual(f.wait(), [1, 2, 3])
    }

    // MARK: -

    func testContains() {
        do {
            let f = makeStream(0..<3).contains(2)
            XCTAssertTrue(f.wait())
        }
        do {
            let f = makeStream(0..<3).contains(42)
            XCTAssertFalse(f.wait())
        }
    }

    func testContainsWhere() {
        do {
            let f = makeStream(0..<3).contains {
                $0 == 2
            }
            XCTAssertTrue(f.wait())
        }
        do {
            let f = makeStream(0..<3).contains {
                $0 == 42
            }
            XCTAssertFalse(f.wait())
        }
    }

    func testAllSatisfy() {
        do {
            let f = makeStream(0..<3).allSatisfy {
                $0 < 3
            }
            XCTAssertTrue(f.wait())
        }
        do {
            let f = makeStream(0..<3).allSatisfy {
                $0 > 0
            }
            XCTAssertFalse(f.wait())
        }
    }

    // MARK: -

    func testDropUntilOutput() {
        var pollCount = 0
        let f = AnyFuture<Void> { _ in
            if pollCount == 2 {
                return .ready(())
            }
            pollCount += 1
            return .pending
        }
        var s = makeStream(0..<3).drop(untilOutputFrom: f)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testDropWhile() {
        var s = makeStream(0..<3).drop(while: { $0 < 2 })
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testDropFirst() {
        do {
            var s = makeStream(0..<3).dropFirst()
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).dropFirst(2)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
    }

    func testAppend() {
        do {
            var s = makeStream(0..<3).append(3, 4, 5)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).append(3..<6)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertNil(s.next())
        }
        do {
            let a = makeStream(3..<6)
            var s = makeStream(0..<3).append(a)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertNil(s.next())
        }
    }

    func testPrepend() {
        do {
            var s = makeStream(0..<3).prepend(3, 4, 5)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).prepend(3..<6)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            let a = makeStream(3..<6)
            var s = makeStream(0..<3).prepend(a)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
    }

    func testPrefixUntilOutput() {
        var pollCount = 0
        let f = AnyFuture<Void> { _ in
            if pollCount == 3 {
                return .ready(())
            }
            pollCount += 1
            return .pending
        }
        var s = makeStream(0..<3).prefix(untilOutputFrom: f)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertNil(s.next())
    }

    func testPrefix() {
        do {
            var s = makeStream(0..<3).prefix(0)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).prefix(1)
            XCTAssertEqual(s.next(), 0)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).prefix(2)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).prefix(3)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).prefix(42)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
    }

    func testPrefixWhile() {
        var s = makeStream(0..<3).prefix {
            $0 < 2
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertNil(s.next())
    }

    func testBuffer() {
        var s = makeStream(0...4).buffer(2)
        XCTAssertEqual(s.next(), [0, 1])
        XCTAssertEqual(s.next(), [2, 3])
        XCTAssertEqual(s.next(), [4])
        XCTAssertNil(s.next())
    }

    func testForEach() {
        var buffer = [Int]()
        var s = makeStream(0..<3).forEach {
            buffer.append($0)
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
        XCTAssertEqual(buffer, [0, 1, 2])
    }

    func testEnumerate() {
        var s = makeStream(0..<3).enumerate()
        XCTAssert(s.next()! == (offset: 0, output: 0))
        XCTAssert(s.next()! == (offset: 1, output: 1))
        XCTAssert(s.next()! == (offset: 2, output: 2))
        XCTAssertNil(s.next())
    }

    // MARK: -

    func testFirst() {
        let f = makeStream(0..<3).first()
        XCTAssertEqual(f.wait(), 0)
    }

    func testFirstWhere() {
        let f = makeStream(0..<3).first(where: { $0 > 1 })
        XCTAssertEqual(f.wait(), 2)
    }

    func testLast() {
        let f = makeStream(0..<3).last()
        XCTAssertEqual(f.wait(), 2)
    }

    func testLastWhere() {
        let f = makeStream(0..<3).last(where: { $0 < 2 })
        XCTAssertEqual(f.wait(), 1)
    }

    func testOutputAt() {
        do {
            var s = makeStream(0..<3).output(at: 0)
            XCTAssertEqual(s.next(), 0)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(at: 1)
            XCTAssertEqual(s.next(), 1)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(at: 2)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(at: 42)
            XCTAssertNil(s.next())
        }
    }

    func testOutputIn() {
        do {
            var s = makeStream(0..<3).output(in: 0...2)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(in: 0..<3)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(in: 1...1)
            XCTAssertEqual(s.next(), 1)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(in: 1..<2)
            XCTAssertEqual(s.next(), 1)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(in: 10...42)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3).output(in: 10..<43)
            XCTAssertNil(s.next())
        }
    }

    func testLatest() {
        do {
            var s = makeStream(0..<3, yieldOnIndex: 0).latest()
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3, yieldOnIndex: 1).latest()
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
        do {
            var s = makeStream(0..<3, yieldOnIndex: 2).latest()
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 2)
            XCTAssertNil(s.next())
        }
    }

    // MARK: -

    func testMergeAll() {
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            var s = Stream.mergeAll([a, b, c])
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            var s = Stream.mergeAll(a, b, c)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertNil(s.next())
        }
    }

    func testMerge() {
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            var s = Stream.merge(a, b)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            var s = Stream.merge(a, b, c)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            let d = Stream.sequence(9..<12)
            var s = Stream.merge(a, b, c, d)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 9)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 10)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertEqual(s.next(), 11)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            var s = a.merge(b)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            var s = a.merge(b, c)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence(0..<3)
            let b = Stream.sequence(3..<6)
            let c = Stream.sequence(6..<9)
            let d = Stream.sequence(9..<12)
            var s = a.merge(b, c, d)
            XCTAssertEqual(s.next(), 0)
            XCTAssertEqual(s.next(), 3)
            XCTAssertEqual(s.next(), 6)
            XCTAssertEqual(s.next(), 9)
            XCTAssertEqual(s.next(), 1)
            XCTAssertEqual(s.next(), 4)
            XCTAssertEqual(s.next(), 7)
            XCTAssertEqual(s.next(), 10)
            XCTAssertEqual(s.next(), 2)
            XCTAssertEqual(s.next(), 5)
            XCTAssertEqual(s.next(), 8)
            XCTAssertEqual(s.next(), 11)
            XCTAssertNil(s.next())
        }
    }

    func testZip() {
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            var s = Stream.zip(a, b)
            XCTAssert(s.next()! == (1, "A"))
            XCTAssert(s.next()! == (2, "B"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            var s = Stream.zip(a, b, c)
            XCTAssert(s.next()! == (1, "A", "X"))
            XCTAssert(s.next()! == (2, "B", "Y"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            let d = Stream.sequence(3..<6)
            var s = Stream.zip(a, b, c, d)
            XCTAssert(s.next()! == (1, "A", "X", 3))
            XCTAssert(s.next()! == (2, "B", "Y", 4))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            var s = a.zip(b)
            XCTAssert(s.next()! == (1, "A"))
            XCTAssert(s.next()! == (2, "B"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            var s = a.zip(b, c)
            XCTAssert(s.next()! == (1, "A", "X"))
            XCTAssert(s.next()! == (2, "B", "Y"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            let d = Stream.sequence(3..<6)
            var s = a.zip(b, c, d)
            XCTAssert(s.next()! == (1, "A", "X", 3))
            XCTAssert(s.next()! == (2, "B", "Y", 4))
            XCTAssertNil(s.next())
        }
    }

    func testJoin() {
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            var s = Stream.join(a, b)
            XCTAssert(s.next()! == (1, "A"))
            XCTAssert(s.next()! == (2, "B"))
            XCTAssert(s.next()! == (2, "C"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            var s = Stream.join(a, b, c)
            XCTAssert(s.next()! == (1, "A", "X"))
            XCTAssert(s.next()! == (2, "B", "Y"))
            XCTAssert(s.next()! == (2, "C", "Z"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            let d = Stream.sequence(3..<6)
            var s = Stream.join(a, b, c, d)
            XCTAssert(s.next()! == (1, "A", "X", 3))
            XCTAssert(s.next()! == (2, "B", "Y", 4))
            XCTAssert(s.next()! == (2, "C", "Z", 5))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            var s = a.join(b)
            XCTAssert(s.next()! == (1, "A"))
            XCTAssert(s.next()! == (2, "B"))
            XCTAssert(s.next()! == (2, "C"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            var s = a.join(b, c)
            XCTAssert(s.next()! == (1, "A", "X"))
            XCTAssert(s.next()! == (2, "B", "Y"))
            XCTAssert(s.next()! == (2, "C", "Z"))
            XCTAssertNil(s.next())
        }
        do {
            let a = Stream.sequence([1, 2])
            let b = Stream.sequence(["A", "B", "C"])
            let c = Stream.sequence(["X", "Y", "Z"])
            let d = Stream.sequence(3..<6)
            var s = a.join(b, c, d)
            XCTAssert(s.next()! == (1, "A", "X", 3))
            XCTAssert(s.next()! == (2, "B", "Y", 4))
            XCTAssert(s.next()! == (2, "C", "Z", 5))
            XCTAssertNil(s.next())
        }
    }

    // MARK: -

    func testSwitchToLatest() {
        let a = makeStream(0..<3, yieldOnIndex: 1).map {
            Stream.sequence($0..<($0 + 3))
        }
        var s = a.switchToLatest()
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertEqual(s.next(), 4)
        XCTAssertNil(s.next())
    }

    func testFlatten() {
        let a = makeStream(0..<3, yieldOnIndex: 1).map {
            makeStream($0..<($0 + 3))
        }
        var s = a.flatten()
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 1)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertEqual(s.next(), 2)
        XCTAssertEqual(s.next(), 3)
        XCTAssertEqual(s.next(), 4)
        XCTAssertNil(s.next())
    }

    // MARK: -

    enum UltimateQuestionError: Error, Equatable {
        case wrongAnswer
    }

    func validateAnswer(_ answer: Int) throws -> Int {
        if answer == 1 {
            throw UltimateQuestionError.wrongAnswer
        }
        return answer
    }

    // MARK: -

    func testTryMap() {
        var s = makeStream(0..<3).tryMap(validateAnswer)
        XCTAssertSuccess(s.next()!, 0)
        XCTAssertNotNil(s.next()?.error)
        XCTAssertSuccess(s.next()!, 2)
        XCTAssertNil(s.next())
    }

    func testSetFailureType() {
        do {
            var s = makeStream(0..<3).setFailureType(to: UltimateQuestionError.self)
            XCTAssertSuccess(s.next()!, 0)
            XCTAssertSuccess(s.next()!, 1)
            XCTAssertSuccess(s.next()!, 2)
            XCTAssertNil(s.next())
        }
        do {
            let a = makeStream(0..<3).map(Result<Int, Never>.success)
            var s = a.setFailureType(to: UltimateQuestionError.self)
            XCTAssertSuccess(s.next()!, 0)
            XCTAssertSuccess(s.next()!, 1)
            XCTAssertSuccess(s.next()!, 2)
            XCTAssertNil(s.next())
        }
    }

    // MARK: -

    func testMatchResult() {
        let a = makeStream(0..<3).tryMap(validateAnswer)
        var s = a.match(
            success: String.init,
            failure: String.init(describing:)
        )
        XCTAssertEqual(s.next(), "0")
        XCTAssertEqual(s.next(), "wrongAnswer")
        XCTAssertEqual(s.next(), "2")
        XCTAssertNil(s.next())
    }

    func testMapValue() {
        var s = makeStream(0..<3).tryMap(validateAnswer).mapValue {
            $0 + 1
        }
        XCTAssertSuccess(s.next()!, 1)
        XCTAssertNotNil(s.next()?.error)
        XCTAssertSuccess(s.next()!, 3)
        XCTAssertNil(s.next())
    }

    func testMapError() {
        struct WrappedError: Error {
            let error: Error
        }
        var s = makeStream(0..<3).tryMap(validateAnswer).mapError {
            WrappedError(error: $0)
        }
        XCTAssertSuccess(s.next()!, 0)
        XCTAssertNotNil(s.next()?.error)
        XCTAssertSuccess(s.next()!, 2)
        XCTAssertNil(s.next())
    }

    func testFlattenResult() {
        let a = makeStream(0..<3)
            .tryMap(validateAnswer)
            .mapValue { Result<Int, Error>.success($0) }
        var s = a.flattenResult()
        XCTAssertSuccess(s.next()!, 0)
        XCTAssertNotNil(s.next()?.error)
        XCTAssertSuccess(s.next()!, 2)
        XCTAssertNil(s.next())
    }

    // MARK: -

    // TODO: testAssertNoError()

    func testCompleteOnError() {
        var s = makeStream(0..<3).tryMap(validateAnswer).completeOnError()
        XCTAssertSuccess(s.next()!, 0)
        XCTAssertNotNil(s.next()?.error)
        XCTAssertNil(s.next())
    }

    func testReplaceError() {
        var s = makeStream(0..<3).tryMap(validateAnswer).replaceError(with: 42)
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    func testCatchError() {
        var s = makeStream(0..<3).tryMap(validateAnswer).catchError { _ in
            Stream.just(42)
        }
        XCTAssertEqual(s.next(), 0)
        XCTAssertEqual(s.next(), 42)
        XCTAssertEqual(s.next(), 2)
        XCTAssertNil(s.next())
    }

    // MARK: -

    // TODO: testMeasureInterval()
    // TODO: testDebounce()
    // TODO: testDelay()
    // TODO: testThrottle()
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
