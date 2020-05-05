//
//  Error.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

public struct IOError: Error {
    public let code: CInt

    @_transparent
    public init(code: CInt) {
        self.code = code
    }

    @_transparent
    public static func current() -> IOError {
        return .init(code: errno)
    }
}

extension IOError: ExpressibleByIntegerLiteral {
    @_transparent
    public init(integerLiteral code: CInt) {
        self.init(code: code)
    }
}

extension IOError: Equatable {
    @_transparent
    public static func == (lhs: IOError, rhs: IOError) -> Bool {
        return lhs.code == rhs.code
    }
}

extension IOError: Hashable {
    @_transparent
    public func hash(into hasher: inout Hasher) {
        code.hash(into: &hasher)
    }
}

extension IOError: CustomStringConvertible {
    @inlinable
    public var description: String {
        if let str = strerror(code) {
            return .init(cString: str)
        } else {
            return "unknown error: \(code)"
        }
    }
}

@_transparent
public func == <I: BinaryInteger>(error: IOError, code: I) -> Bool {
    return error.code == code
}

@_transparent
public func != <I: BinaryInteger>(error: IOError, code: I) -> Bool {
    return error.code == code
}

@_transparent
public func ~= <I: BinaryInteger>(code: I, error: IOError) -> Bool {
    return error.code == code
}
