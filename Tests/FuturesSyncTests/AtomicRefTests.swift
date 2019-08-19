//
//  AtomicRefTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync
import FuturesTestSupport
import XCTest

final class AtomicRefTests: XCTestCase {
    func testDoesNotLeak() {
        class SomeClass {}
        weak var weakSomeInstance1: SomeClass?
        weak var weakSomeInstance2: SomeClass?
        ({
            let someInstance = SomeClass()
            weakSomeInstance1 = someInstance
            let someAtomic = AtomicRef(someInstance)
            let loadedFromAtomic = someAtomic.load()
            weakSomeInstance2 = loadedFromAtomic
            XCTAssertNotNil(weakSomeInstance1)
            XCTAssertNotNil(weakSomeInstance2)
            XCTAssert(someInstance === loadedFromAtomic)
        })()
        XCTAssertNil(weakSomeInstance1)
        XCTAssertNil(weakSomeInstance2)
    }

    func testCompareExchangeIfEqual() throws {
        class SomeClass {}
        weak var weakSomeInstance1: SomeClass?
        weak var weakSomeInstance2: SomeClass?
        weak var weakSomeInstance3: SomeClass?
        ({
            let someInstance1 = SomeClass()
            let someInstance2 = SomeClass()
            weakSomeInstance1 = someInstance1

            let atomic = AtomicRef(someInstance1)
            var loadedFromAtomic = atomic.load()
            XCTAssert(someInstance1 === loadedFromAtomic)
            weakSomeInstance2 = loadedFromAtomic

            XCTAssert(loadedFromAtomic === atomic.compareExchange(loadedFromAtomic, someInstance2))

            loadedFromAtomic = atomic.load()
            weakSomeInstance3 = loadedFromAtomic
            XCTAssert(someInstance1 !== loadedFromAtomic)
            XCTAssert(someInstance2 === loadedFromAtomic)

            XCTAssertNotNil(weakSomeInstance1)
            XCTAssertNotNil(weakSomeInstance2)
            XCTAssertNotNil(weakSomeInstance3)
            XCTAssert(weakSomeInstance1 === weakSomeInstance2 && weakSomeInstance2 !== weakSomeInstance3)
        })()
        XCTAssertNil(weakSomeInstance1)
        XCTAssertNil(weakSomeInstance2)
        XCTAssertNil(weakSomeInstance3)
    }

    func testCompareExchangeNotEqual() throws {
        class SomeClass {}
        weak var weakSomeInstance1: SomeClass?
        weak var weakSomeInstance2: SomeClass?
        weak var weakSomeInstance3: SomeClass?
        ({
            let someInstance1 = SomeClass()
            let someInstance2 = SomeClass()
            weakSomeInstance1 = someInstance1

            let atomic = AtomicRef(someInstance1)
            var loadedFromAtomic = atomic.load()
            XCTAssert(someInstance1 === loadedFromAtomic)
            weakSomeInstance2 = loadedFromAtomic

            XCTAssert(loadedFromAtomic === atomic.compareExchange(someInstance2, someInstance2))
            XCTAssert(loadedFromAtomic === atomic.compareExchange(SomeClass(), someInstance2))
            XCTAssert(someInstance1 === atomic.load())

            loadedFromAtomic = atomic.load()
            weakSomeInstance3 = someInstance2
            XCTAssert(someInstance1 === loadedFromAtomic)
            XCTAssert(someInstance2 !== loadedFromAtomic)

            XCTAssertNotNil(weakSomeInstance1)
            XCTAssertNotNil(weakSomeInstance2)
            XCTAssertNotNil(weakSomeInstance3)
        })()
        XCTAssertNil(weakSomeInstance1)
        XCTAssertNil(weakSomeInstance2)
        XCTAssertNil(weakSomeInstance3)
    }

    func testCompareExchangeSelf() {
        let q = DispatchQueue(label: "futures.test")
        let g = DispatchGroup()
        let sem1 = DispatchSemaphore(value: 0)
        let sem2 = DispatchSemaphore(value: 0)
        class SomeClass {}
        weak var weakInstance: SomeClass?
        ({
            var instance: Optional = SomeClass()
            weakInstance = instance

            let atomic = AtomicRef(instance)
            q.async(group: g, flags: .detached) {
                sem1.signal()
                sem2.wait()
                for _ in 0..<1_000 {
                    XCTAssertTrue(atomic.compareExchange(&instance, instance))
                    XCTAssert(instance === atomic.compareExchange(instance, instance))
                }
            }
            sem2.signal()
            sem1.wait()
            for _ in 0..<1_000 {
                XCTAssert(instance === atomic.compareExchange(instance, instance))
            }
            g.wait()
            let v = atomic.load()
            XCTAssert(v === instance)
        })()
        XCTAssertNil(weakInstance)
    }

    func testStore() throws {
        class SomeClass {}
        weak var weakSomeInstance1: SomeClass?
        weak var weakSomeInstance2: SomeClass?
        weak var weakSomeInstance3: SomeClass?
        ({
            let someInstance1 = SomeClass()
            let someInstance2 = SomeClass()
            weakSomeInstance1 = someInstance1

            let atomic = AtomicRef(someInstance1)
            var loadedFromAtomic = atomic.load()
            XCTAssert(someInstance1 === loadedFromAtomic)
            weakSomeInstance2 = loadedFromAtomic

            atomic.store(someInstance2)

            loadedFromAtomic = atomic.load()
            weakSomeInstance3 = loadedFromAtomic
            XCTAssert(someInstance1 !== loadedFromAtomic)
            XCTAssert(someInstance2 === loadedFromAtomic)

            XCTAssertNotNil(weakSomeInstance1)
            XCTAssertNotNil(weakSomeInstance2)
            XCTAssertNotNil(weakSomeInstance3)
        })()
        XCTAssertNil(weakSomeInstance1)
        XCTAssertNil(weakSomeInstance2)
        XCTAssertNil(weakSomeInstance3)
    }
}
