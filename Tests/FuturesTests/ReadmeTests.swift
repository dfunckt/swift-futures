//
//  ReadmeTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import XCTest

func isPrime(_ n: Int) -> Bool {
    return n == 2 || n > 2 && (2...(n - 1)).allSatisfy {
        !n.isMultiple(of: $0)
    }
}

func isPronic(_ n: Int) -> Bool {
    let f = floor(Double(n).squareRoot())
    let c = ceil(Double(n).squareRoot())
    return n == Int(f) * Int(c)
}

final class ReadmeTests: XCTestCase {
    func test42Stream() {
        let integers = Stream.sequence(0...)
        let primes = integers.filter(isPrime)

        let answer = primes.buffer(4)
            .map { $0[0] * $0[1] * $0[3] }
            .first(where: isPronic)

        XCTAssertEqual(answer.wait(), 42)
    }

    func test42Channel() {
        let deepThought = (
            cpu0: QueueExecutor(label: "CPU 0"),
            cpu1: QueueExecutor(label: "CPU 1"),
            cpu2: QueueExecutor(label: "CPU 2")
        )

        let pipe1 = Channel.makeUnbuffered(itemType: Int.self)
        let pipe2 = Channel.makeUnbuffered(itemType: Int.self)

        let integers = Stream.sequence(0...)
        deepThought.cpu1.submit(integers.forward(to: pipe1))

        let primes = pipe1.makeStream().filter(isPrime)
        deepThought.cpu2.submit(primes.forward(to: pipe2))

        let answer = deepThought.cpu0.spawn(
            pipe2.makeStream()
                .buffer(4)
                .map { $0[0] * $0[1] * $0[3] }
                .first(where: isPronic)
        )

        XCTAssertEqual(answer.wait(), 42)
    }
}
