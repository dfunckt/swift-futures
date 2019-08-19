//
//  Either.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public protocol EitherConvertible {
    associatedtype Left
    associatedtype Right
    nonmutating func makeEither() -> Either<Left, Right>
}

public enum Either<A, B> {
    case left(A)
    case right(B)
}

extension Either: Equatable where A: Equatable, B: Equatable {}
extension Either: Hashable where A: Hashable, B: Hashable {}

extension Either: EitherConvertible {
    @_transparent
    public func makeEither() -> Either {
        return self
    }
}

extension Either where B: Error {
    @inlinable
    public init(result: Result<A, B>) {
        switch result {
        case .success(let a):
            self = .left(a)
        case .failure(let b):
            self = .right(b)
        }
    }

    @inlinable
    public func makeResult() -> Result<A, B> {
        switch self {
        case .left(let a):
            return .success(a)
        case .right(let b):
            return .failure(b)
        }
    }
}

extension Either where A == Void {
    @inlinable
    public static var left: Either {
        return .left(())
    }
}

extension Either where B == Void {
    @inlinable
    public static var right: Either {
        return .right(())
    }
}

extension Either {
    @inlinable
    public var left: A? {
        if case .left(let a) = self {
            return a
        }
        return nil
    }

    @inlinable
    public var right: B? {
        if case .right(let b) = self {
            return b
        }
        return nil
    }

    @inlinable
    public var isLeft: Bool {
        switch self {
        case .left:
            return true
        case .right:
            return false
        }
    }

    @inlinable
    public var isRight: Bool {
        switch self {
        case .left:
            return false
        case .right:
            return true
        }
    }
}

extension Either {
    @inlinable
    public func match<R>(left: (A) throws -> R, right: (B) throws -> R) rethrows -> R {
        switch self {
        case .left(let a):
            return try left(a)
        case .right(let b):
            return try right(b)
        }
    }

    @inlinable
    public func map<L>(_ fn: (A) -> L) -> Either<L, B> {
        switch self {
        case .left(let a):
            return .left(fn(a))
        case .right(let b):
            return .right(b)
        }
    }

    @inlinable
    public func mapRight<R>(_ fn: (B) -> R) -> Either<A, R> {
        switch self {
        case .left(let a):
            return .left(a)
        case .right(let b):
            return .right(fn(b))
        }
    }

    @inlinable
    public func flatMap<L>(_ fn: (A) -> Either<L, B>) -> Either<L, B> {
        switch self {
        case .left(let a):
            return fn(a)
        case .right(let b):
            return .right(b)
        }
    }

    @inlinable
    public func flatMapRight<R>(_ fn: (B) -> Either<A, R>) -> Either<A, R> {
        switch self {
        case .left(let a):
            return .left(a)
        case .right(let b):
            return fn(b)
        }
    }

    @inlinable
    public func split<T, L, R>() -> (T, Either<L, R>) where A == (T, L), B == (T, R) {
        switch self {
        case .left(let (t, a)):
            return (t, .left(a))
        case .right(let (t, b)):
            return (t, .right(b))
        }
    }

    @inlinable
    public func splitRight<L, R, T>() -> (Either<L, R>, T) where A == (L, T), B == (R, T) {
        switch self {
        case .left(let (a, t)):
            return (.left(a), t)
        case .right(let (b, t)):
            return (.right(b), t)
        }
    }
}

extension Either: FutureConvertible where A: FutureConvertible, B: FutureConvertible {
    @inlinable
    public func makeFuture() -> Either<A.FutureType, B.FutureType> {
        switch self {
        case .left(let a):
            return .left(a.makeFuture())
        case .right(let b):
            return .right(b.makeFuture())
        }
    }
}

extension Either: FutureProtocol where A: FutureProtocol, B: FutureProtocol {
    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Either<A.Output, B.Output>> {
        switch self {
        case .left(var a):
            let r = a.poll(&context)
            self = .left(a)
            switch r {
            case .ready(let output):
                return .ready(.left(output))
            case .pending:
                return .pending
            }
        case .right(var b):
            let r = b.poll(&context)
            self = .right(b)
            switch r {
            case .ready(let output):
                return .ready(.right(output))
            case .pending:
                return .pending
            }
        }
    }
}
