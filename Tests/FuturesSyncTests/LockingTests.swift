//
//  LockingTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync
import FuturesTestSupport
import XCTest

public final class LockingTests: XCTestCase {
    private func lockTest(_ config: (Int, Int), _ lock: LockingProtocol) {
        let (partitions, iterations) = (UInt64(config.0), UInt64(config.1))
        let q = DispatchQueue(label: "futures.test-locking", attributes: .concurrent)
        let g = DispatchGroup()
        var i: UInt64 = 0
        for p in 1...partitions {
            q.async(group: g, flags: .detached) {
                for _ in 0..<iterations {
                    lock.sync {
                        i += p
                    }
                }
            }
        }
        g.wait()
        XCTAssertEqual(i, (partitions * (partitions + 1) / 2) * iterations, "Failed: \(lock.self)")
    }

    public func testContented() {
        let c = (CPU_COUNT * 4, 1_000)
        let g = DispatchGroup()
        let q = DispatchQueue(label: "futures.test-locking.contented")
        q.async(group: g) { self.lockTest(c, PosixLock(recursive: true)) }
        q.async(group: g) { self.lockTest(c, PosixLock()) }
        q.async(group: g) { self.lockTest(c, SpinLock()) }
        q.async(group: g) { self.lockTest(c, UnfairLock()) }
        g.wait()
    }

    public func testUncontented() {
        let c = (CPU_COUNT, 5_000)
        let g = DispatchGroup()
        let q = DispatchQueue(label: "futures.test-locking.uncontented")
        q.async(group: g) { self.lockTest(c, PosixLock(recursive: true)) }
        q.async(group: g) { self.lockTest(c, PosixLock()) }
        q.async(group: g) { self.lockTest(c, SpinLock()) }
        q.async(group: g) { self.lockTest(c, UnfairLock()) }
        g.wait()
    }
}
