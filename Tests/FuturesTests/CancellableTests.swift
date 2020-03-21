//
//  CancellableTests.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import XCTest

final class CancellableTests: XCTestCase {
    func testAnyCancellable() {
        expect(count: 1) { exp in
            let c1 = AnyCancellable { exp[0].fulfill() }
            let c2 = AnyCancellable(c1)
            c2.cancel()
        }
        expect(count: 1) { exp in
            let c1 = AnyCancellable { exp[0].fulfill() } as Cancellable
            let c2 = AnyCancellable(c1)
            c2.cancel()
        }
        expect(count: 1) { exp in
            let c1 = AnyCancellable { exp[0].fulfill() }
            _ = AnyCancellable(c1)
        }
        expect(count: 1) { exp in
            _ = AnyCancellable { exp[0].fulfill() }
        }
    }
}
