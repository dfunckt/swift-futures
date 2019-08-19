//
//  Module.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Foundation

public let DONE: Void = ()

public let CPU_COUNT = ProcessInfo.processInfo.processorCount

private var rng = SystemRandomNumberGenerator()

public func randomInteger<T: FixedWidthInteger>(ofType type: T.Type = T.self) -> T {
    var t = type.init()
    for _ in 0...((t.bitWidth - 1) / 32) {
        t = t << 32 &+ type.init(truncatingIfNeeded: rng.next())
    }
    return (t | 1) & (type.max >> 1)
}

public struct AnyError: Error {
    public let error: Error

    public init(_ error: Error) {
        if let anyError = error as? AnyError {
            self = anyError
        } else {
            self.error = error
        }
    }
}

public final class Ref<T> {
    public var value: T

    public init(_ initialValue: T) {
        value = initialValue
    }
}

extension Swift.Result {
    public var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
