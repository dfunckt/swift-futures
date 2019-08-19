//
//  TestError.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public enum TestError: Error, Equatable {
    case dummy
    case custom(Int)

    public static func == (lhs: TestError, rhs: TestError) -> Bool {
        switch (lhs, rhs) {
        case (.dummy, .dummy):
            return true
        case (.custom(let a), .custom(let b)):
            return a == b
        default:
            return false
        }
    }

    public static func == (lhs: TestError, rhs: Error) -> Bool {
        guard let rhs = rhs as? TestError else {
            return false
        }
        return lhs == rhs
    }

    public static func == (lhs: Error, rhs: TestError) -> Bool {
        guard let lhs = lhs as? TestError else {
            return false
        }
        return lhs == rhs
    }

    public static func == (lhs: Error?, rhs: TestError) -> Bool {
        guard let lhs = lhs as? TestError else {
            return false
        }
        return lhs == rhs
    }
}
