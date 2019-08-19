//
//  AtomicValueTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync
import FuturesTestSupport
import XCTest

final class AtomicValueTests: XCTestCase {
    func testConsistency() {
        let PARTITIONS = 128
        let ITERATIONS = 10_000
        let total = (PARTITIONS * (PARTITIONS + 1) / 2) * ITERATIONS

        let q = DispatchQueue(label: "futures.test-atomic", attributes: .concurrent)
        let g = DispatchGroup()

        let counter = AtomicInt(0)

        for p in 1...PARTITIONS {
            q.async(group: g, flags: .detached) {
                for _ in 0..<ITERATIONS {
                    counter.fetchAdd(p)
                }
            }
        }

        g.wait()
        XCTAssertEqual(counter.load(), total)
    }

    func testBool() {
        let i = AtomicBool(false)
        XCTAssert(i.load() == false)

        i.store(false)
        XCTAssert(i.load() == false)

        i.store(true)
        XCTAssert(i.load() == true)

        i.store(true)
        i.fetchOr(true)
        XCTAssert(i.load() == true)
        i.fetchOr(false)
        XCTAssert(i.load() == true)
        i.store(false)
        i.fetchOr(false)
        XCTAssert(i.load() == false)
        i.fetchOr(true)
        XCTAssert(i.load() == true)

        i.fetchAnd(false)
        XCTAssert(i.load() == false)
        i.fetchAnd(true)
        XCTAssert(i.load() == false)

        i.fetchXor(false)
        XCTAssert(i.load() == false)
        i.fetchXor(true)
        XCTAssert(i.load() == true)

        var old = i.exchange(false)
        XCTAssert(old == true)
        XCTAssert(i.exchange(true) == false)

        i.store(false)
        XCTAssert(i.compareExchange(false, true) == false)
        XCTAssert(i.compareExchange(true, false) == true)
        XCTAssert(i.compareExchange(&old, false) == false)
        XCTAssert(i.compareExchange(old, true) == old)

        old = i.exchange(false)
        XCTAssert(old == true)
        XCTAssert(i.exchange(true) == false)

        i.store(false)
        XCTAssert(i.compareExchangeWeak(false, true) == false)
        XCTAssert(i.compareExchangeWeak(true, false) == true)
        XCTAssert(i.compareExchangeWeak(&old, false) == false)
        XCTAssert(i.compareExchangeWeak(old, true) == old)
    }

    func testInt() {
        let i = AtomicInt(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: Int.self)
        let r2 = randomInteger(ofType: Int.self)
        let r3 = randomInteger(ofType: Int.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testInt8() {
        let i = AtomicInt8(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: Int8.self)
        let r2 = randomInteger(ofType: Int8.self)
        let r3 = randomInteger(ofType: Int8.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testInt16() {
        let i = AtomicInt16(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: Int16.self)
        let r2 = randomInteger(ofType: Int16.self)
        let r3 = randomInteger(ofType: Int16.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testInt32() {
        let i = AtomicInt32(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: Int32.self)
        let r2 = randomInteger(ofType: Int32.self)
        let r3 = randomInteger(ofType: Int32.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testInt64() {
        let i = AtomicInt64(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: Int64.self)
        let r2 = randomInteger(ofType: Int64.self)
        let r3 = randomInteger(ofType: Int64.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testUInt() {
        let i = AtomicUInt(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: UInt.self)
        let r2 = randomInteger(ofType: UInt.self)
        let r3 = randomInteger(ofType: UInt.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testUInt8() {
        let i = AtomicUInt8(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: UInt8.self)
        let r2 = randomInteger(ofType: UInt8.self)
        let r3 = randomInteger(ofType: UInt8.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testUInt16() {
        let i = AtomicUInt16(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: UInt16.self)
        let r2 = randomInteger(ofType: UInt16.self)
        let r3 = randomInteger(ofType: UInt16.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testUInt32() {
        let i = AtomicUInt32(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: UInt32.self)
        let r2 = randomInteger(ofType: UInt32.self)
        let r3 = randomInteger(ofType: UInt32.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }

    func testUInt64() {
        let i = AtomicUInt64(0)
        XCTAssert(i.load() == 0)

        let r1 = randomInteger(ofType: UInt64.self)
        let r2 = randomInteger(ofType: UInt64.self)
        let r3 = randomInteger(ofType: UInt64.self)

        i.store(r1)
        XCTAssert(r1 == i.load())

        var j = i.exchange(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r2, i.load())

        j = i.fetchAdd(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 &+ r2, i.load())

        j = i.fetchSub(r2)
        XCTAssertEqual(r1 &+ r2, j)
        XCTAssertEqual(r1, i.load())

        i.store(r1)
        j = i.fetchOr(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 | r2, i.load())

        i.store(r2)
        j = i.fetchXor(r1)
        XCTAssertEqual(r2, j)
        XCTAssertEqual(r1 ^ r2, i.load())

        i.store(r1)
        j = i.fetchAnd(r2)
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r1 & r2, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchange(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchange(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())

        i.store(r1)
        XCTAssertTrue(i.compareExchangeWeak(r1, r2) == r1)
        XCTAssertEqual(r2, i.load())

        j = r2
        i.store(r1)
        while !i.compareExchangeWeak(&j, r3) {}
        XCTAssertEqual(r1, j)
        XCTAssertEqual(r3, i.load())
    }
}
