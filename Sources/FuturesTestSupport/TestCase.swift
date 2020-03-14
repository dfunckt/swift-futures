//
//  TestCase.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import XCTest

extension XCTestCase {
    public func expect<R>(
        function: StaticString = #function,
        count: Int = 1,
        description: String? = nil,
        timeout: TimeInterval = 1,
        enforceOrder enforceOrderOfFulfillment: Bool = true,
        execute: ([XCTestExpectation]) throws -> R
    ) rethrows -> R {
        var exp = [XCTestExpectation]()
        for i in 0..<count {
            exp.append(expectation(
                description: description ?? "\(function)#\(i)"
            ))
        }
        let result = try execute(exp)
        wait(for: exp, timeout: timeout, enforceOrder: enforceOrderOfFulfillment)
        return result
    }

    public func poll(_ fn: @escaping (inout Context) -> Poll<Void>) throws {
        let executor = ThreadExecutor()
        try executor.submit(AnyFuture(fn))
        XCTAssert(executor.run())
    }
}
