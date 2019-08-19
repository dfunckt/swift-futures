//
//  Result.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public typealias AnyResultFuture<Success, Failure: Error> = AnyFuture<Result<Success, Failure>>
public typealias AnyResultStream<Success, Failure: Error> = AnyStream<Result<Success, Failure>>

extension AnyFuture {
    @inlinable
    public init<T>(_ pollFn: @escaping (inout Context) throws -> Poll<T>) where Output == Result<T, Error> {
        self.init { context in
            do {
                return try pollFn(&context).map(Result.success)
            } catch {
                return .ready(.failure(error))
            }
        }
    }
}

extension AnyStream {
    @inlinable
    public init<T>(_ pollNextFn: @escaping (inout Context) throws -> Poll<T?>) where Output == Result<T, Error> {
        self.init { context in
            do {
                return try pollNextFn(&context).map {
                    $0.map(Result.success)
                }
            } catch {
                return .ready(.failure(error))
            }
        }
    }
}

// MARK: -

public struct ResultFuture<Success, Failure: Error>: FutureProtocol {
    public typealias Output = Result<Success, Failure>

    @usableFromInline
    enum _State {
        case pending(Output)
        case done
    }

    @usableFromInline var _state: _State

    @inlinable
    public init(_ result: Output) {
        _state = .pending(result)
    }

    @inlinable
    public init(value: Success) {
        _state = .pending(.success(value))
    }

    @inlinable
    public init(error: Failure) {
        _state = .pending(.failure(error))
    }

    @inlinable
    public mutating func poll(_: inout Context) -> Poll<Output> {
        switch _state {
        case .pending(let result):
            _state = .done
            return .ready(result)
        case .done:
            fatalError("cannot poll after completion")
        }
    }
}

public struct ResultStream<Success, Failure: Error>: StreamProtocol {
    public typealias Output = Result<Success, Failure>

    @usableFromInline
    enum _State {
        case pending(Output)
        case completed
        case done
    }

    @usableFromInline var _state: _State

    @inlinable
    public init(_ result: Output) {
        _state = .pending(result)
    }

    @inlinable
    public init(value: Success) {
        _state = .pending(.success(value))
    }

    @inlinable
    public init(error: Failure) {
        _state = .pending(.failure(error))
    }

    @inlinable
    public mutating func pollNext(_: inout Context) -> Poll<Output?> {
        switch _state {
        case .pending(let result):
            _state = .completed
            return .ready(result)
        case .completed:
            _state = .done
            return .ready(nil)
        case .done:
            fatalError("cannot poll after completion")
        }
    }
}

extension Swift.Result: FutureConvertible {
    @inlinable
    public func makeFuture() -> ResultFuture<Success, Failure> {
        return .init(self)
    }
}

extension Swift.Result: StreamConvertible {
    @inlinable
    public func makeStream() -> ResultStream<Success, Failure> {
        return .init(self)
    }
}

// MARK: -

extension Promise where Output: _ExpressibleByResult {
    @inlinable
    public func fulfill(_ value: Output.Success) {
        resolve(.init(_result: .success(value)))
    }

    @inlinable
    public func reject(_ error: Output.Failure) {
        resolve(.init(_result: .failure(error)))
    }
}

// MARK: - Private -

// Protocols and extensions for working with Result in Futures.
// This abomination is unfortunately currently required.
// Can be removed when this lands in Swift:
// https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md#parameterized-extensions

/// :nodoc:
public protocol _ExpressibleByResult {
    associatedtype Success
    associatedtype Failure: Error
    init(_result: Result<Success, Failure>)
}

/// :nodoc:
public protocol _ResultConvertible {
    associatedtype Success
    associatedtype Failure: Error
    nonmutating func _makeResult() -> Result<Success, Failure>
}

/// :nodoc:
extension Swift.Result: _ExpressibleByResult, _ResultConvertible {
    @_transparent
    public init(_result: Result) {
        self = _result
    }

    @_transparent
    public func _makeResult() -> Result {
        return self
    }
}

/// :nodoc:
extension Either: _ExpressibleByResult, _ResultConvertible where B: Error {
    @_transparent
    public init(_result: Result<A, B>) {
        self.init(result: _result)
    }

    @_transparent
    public func _makeResult() -> Result<A, B> {
        return makeResult()
    }
}

/// :nodoc:
extension Sink.Completion: _ExpressibleByResult, _ResultConvertible {
    @_transparent
    public init(_result: Result<Void, Failure>) {
        self.init(result: _result)
    }

    @_transparent
    public func _makeResult() -> Result<Void, Failure> {
        return makeResult()
    }
}
