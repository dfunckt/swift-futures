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
                return try pollFn(&context).map { .success($0) }
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
                    $0.map { .success($0) }
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

extension Promise {
    @inlinable
    public func fulfill<Success, Failure: Error>(_ value: Success) where Output == Result<Success, Failure> {
        resolve(.success(value))
    }

    @inlinable
    public func reject<Success, Failure: Error>(_ error: Failure) where Output == Result<Success, Failure> {
        resolve(.failure(error))
    }
}
