//
//  TestCase.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import XCTest

extension XCTestCase {
    public func expect(
        function: StaticString = #function,
        count: Int = 1,
        description: String? = nil,
        timeout: TimeInterval = 1,
        execute: ([XCTestExpectation]) throws -> Void
    ) rethrows {
        var exp = [XCTestExpectation]()
        for i in 0..<count {
            exp.append(expectation(
                description: description ?? "\(function)#\(i)"
            ))
        }
        try execute(exp)
        waitForExpectations(timeout: timeout, handler: nil)
    }

    public func poll(_ fn: @escaping (inout Context) -> Poll<Void>) {
        let executor = ThreadExecutor.current
        executor.submit(AnyFuture(fn))
        XCTAssert(executor.run())
    }
}
