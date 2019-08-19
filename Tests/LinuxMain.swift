//
//  LinuxMain.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import XCTest

import FuturesSyncTests
import FuturesTests

var tests = [XCTestCaseEntry]()
tests += FuturesSyncTests.__allTests()
tests += FuturesTests.__allTests()

XCTMain(tests)
