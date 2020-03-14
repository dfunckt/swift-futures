//
//  Poll.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

/// A value that encapsulates the result of polling a future. See
/// `FutureProtocol.poll(_:)`.
public enum Poll<T> {
    case ready(T)
    case pending
}

extension Poll: Equatable where T: Equatable {}
extension Poll: Hashable where T: Hashable {}

extension Poll where T == Void {
    @inlinable
    public static var ready: Poll {
        return .ready(())
    }
}

extension Poll {
    @inlinable
    public var result: T? {
        switch self {
        case .ready(let result):
            return result
        case .pending:
            return nil
        }
    }

    @inlinable
    public var isReady: Bool {
        switch self {
        case .ready:
            return true
        case .pending:
            return false
        }
    }

    @inlinable
    public var isPending: Bool {
        switch self {
        case .ready:
            return false
        case .pending:
            return true
        }
    }
}

extension Poll {
    @inlinable
    public func match<R>(ready: (T) throws -> R, pending: () throws -> R) rethrows -> R {
        switch self {
        case .ready(let value):
            return try ready(value)
        case .pending:
            return try pending()
        }
    }

    @inlinable
    public func map<U>(_ fn: (T) -> U) -> Poll<U> {
        switch self {
        case .ready(let value):
            return .ready(fn(value))
        case .pending:
            return .pending
        }
    }

    @inlinable
    public func flatMap<U>(_ fn: (T) -> Poll<U>) -> Poll<U> {
        switch self {
        case .ready(let value):
            return fn(value)
        case .pending:
            return .pending
        }
    }
}
