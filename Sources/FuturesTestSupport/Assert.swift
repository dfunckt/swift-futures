//
//  Assert.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

// swiftlint:disable force_unwrapping

import Futures
import XCTest

// MARK: - Poll -

public func XCTAssertEqual<T: Equatable>(
    _ pollResult: Poll<T>,
    _ value: T,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(pollResult.result, value, file: file, line: line)
}

public func XCTAssertReady<T>(
    _ pollResult: Poll<T>,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssert(pollResult.isReady, "not ready", file: file, line: line)
}

public func XCTAssertPending<T>(
    _ pollResult: Poll<T>,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssert(pollResult.isPending, "not pending", file: file, line: line)
}

// MARK: - Result -

public func XCTAssertSuccess<E: Error>(
    _ result: Result<Void, E>,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertNotNil(result.value, file: file, line: line)
}

public func XCTAssertFailure<T, E: Error>(
    _ result: Result<T, E>,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertNotNil(result.error, file: file, line: line)
}

public func XCTAssertSuccess<E: Error>(
    _ pollResult: Poll<Result<Void, E>>,
    file: StaticString = #file,
    line: UInt = #line
) {
    pollResult.match(
        ready: { XCTAssertSuccess($0, file: file, line: line) },
        pending: { XCTFail("not ready", file: file, line: line) }
    )
}

public func XCTAssertFailure<T, E: Error>(
    _ pollResult: Poll<Result<T, E>>,
    file: StaticString = #file,
    line: UInt = #line
) {
    pollResult.match(
        ready: { XCTAssertFailure($0, file: file, line: line) },
        pending: { XCTFail("not ready", file: file, line: line) }
    )
}

public func XCTAssertSuccess<T: Equatable, E: Error>(
    _ result: Result<T, E>,
    _ value: T,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(result.value, value, file: file, line: line)
}

public func XCTAssertFailure<T, E: Error & Equatable>(
    _ result: Result<T, E>,
    _ error: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertEqual(result.error, error, file: file, line: line)
}

public func XCTAssertFailure<T, E: Error & Equatable>(
    _ result: Result<T, Error>,
    _ error: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    // swiftlint:disable:next force_cast
    XCTAssertEqual(result.error! as! E, error, file: file, line: line)
}

public func XCTAssertSuccess<T: Equatable, E: Error>(
    _ pollResult: Poll<Result<T, E>>,
    _ value: T,
    file: StaticString = #file,
    line: UInt = #line
) {
    pollResult.match(
        ready: { XCTAssertSuccess($0, value, file: file, line: line) },
        pending: { XCTFail("not ready", file: file, line: line) }
    )
}

public func XCTAssertFailure<T, E: Error & Equatable>(
    _ pollResult: Poll<Result<T, E>>,
    _ error: E,
    file: StaticString = #file,
    line: UInt = #line
) {
    pollResult.match(
        ready: { XCTAssertFailure($0, error, file: file, line: line) },
        pending: { XCTFail("not ready", file: file, line: line) }
    )
}
