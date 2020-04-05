//
//  Sink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public protocol SinkProtocol: SinkConvertible where SinkType == Self {
    associatedtype Input
    associatedtype Failure: Error

    typealias Completion = Sink.Completion<Failure>
    typealias Output = Result<Void, Completion>

    mutating func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output>
    mutating func pollFlush(_ context: inout Context) -> Poll<Output>
    mutating func pollClose(_ context: inout Context) -> Poll<Output>
}

public protocol SinkConvertible {
    associatedtype SinkType: SinkProtocol
    nonmutating func makeSink() -> SinkType
}

extension SinkConvertible where Self: SinkProtocol {
    @_transparent
    public func makeSink() -> Self {
        return self
    }
}

/// A namespace for types and convenience methods related to sinks.
///
/// For details on sinks, see `SinkProtocol`.
public enum Sink {}

// MARK: - Supporting Types -

extension Sink {
    public enum Completion<Failure: Error>: Error {
        case closed
        case failure(Failure)
    }
}

extension Sink.Completion: Equatable where Failure: Equatable {}
extension Sink.Completion: Hashable where Failure: Hashable {}

extension Sink.Completion {
    @inlinable
    public init(result: Result<Void, Failure>) {
        switch result {
        case .success:
            self = .closed
        case .failure(let error):
            self = .failure(error)
        }
    }

    @inlinable
    public func makeResult() -> Result<Void, Failure> {
        switch self {
        case .closed:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension Sink.Completion {
    @inlinable
    public func mapError<E: Error>(_ transform: (Failure) throws -> E) rethrows -> Sink.Completion<E> {
        switch self {
        case .closed:
            return .closed
        case .failure(let error):
            return try .failure(transform(error))
        }
    }
}

// MARK: - Creating Sinks -

/// A type-erasing sink.
///
/// Use `AnySink` to wrap a sink whose type has details you don’t want to
/// expose. This is typically the case when returning sinks from a function
/// or storing sinks in properties.
///
/// You can also use `AnySink` to create a custom sink by providing a closure
/// for the `pollSend`, `pollFlush` and `pollClose` methods, rather than
/// implementing `SinkProtocol` directly on a custom type.
public struct AnySink<Input, Failure: Error>: SinkProtocol {
    public typealias Output = Result<Void, Sink.Completion<Failure>>

    public typealias PollSendFn = (inout Context, Input) -> Poll<Output>
    public typealias PollFlushFn = (inout Context) -> Poll<Output>
    public typealias PollCloseFn = (inout Context) -> Poll<Output>

    @usableFromInline let _pollSend: PollSendFn
    @usableFromInline let _pollFlush: PollFlushFn
    @usableFromInline let _pollClose: PollCloseFn

    /// Creates a type-erasing sink implemented by the provided closures.
    @inlinable
    public init(pollSend: @escaping PollSendFn, pollFlush: @escaping PollFlushFn, pollClose: @escaping PollCloseFn) {
        _pollSend = pollSend
        _pollFlush = pollFlush
        _pollClose = pollClose
    }

    @inlinable
    public init<Base: SinkProtocol>(_ sink: Base) where Base.Input == Input, Base.Failure == Failure {
        if let s = sink as? AnySink {
            _pollSend = s._pollSend
            _pollFlush = s._pollFlush
            _pollClose = s._pollClose
        } else {
            var s = sink
            _pollSend = { s.pollSend(&$0, $1) }
            _pollFlush = { s.pollFlush(&$0) }
            _pollClose = { s.pollClose(&$0) }
        }
    }

    @inlinable
    public func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output> {
        return _pollSend(&context, item)
    }

    @inlinable
    public func pollFlush(_ context: inout Context) -> Poll<Output> {
        return _pollFlush(&context)
    }

    @inlinable
    public func pollClose(_ context: inout Context) -> Poll<Output> {
        return _pollClose(&context)
    }
}

extension Sink {
    @inlinable
    public static func collect<T>(itemType _: T.Type = T.self) -> _Private.Collect<T> {
        return .init()
    }

    @inlinable
    public static func collect<S: Sequence>(_ initialElements: S) -> _Private.Collect<S.Element> {
        return .init(initialElements: initialElements)
    }
}

// MARK: - Instance Methods -

extension SinkProtocol {
    @inlinable
    public func makeBlockingSink() -> Sink._Private.Blocking<Self> {
        return .init(base: self)
    }

    @inlinable
    public func eraseToAnySink() -> AnySink<Input, Failure> {
        return .init(self)
    }
}

// MARK: - Adapting Input -

extension SinkProtocol {
    @inlinable
    public func map<T>(_ adapt: @escaping (T) -> Input) -> Sink._Private.Map<T, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func mapError<E>(_ adapt: @escaping (Error) -> E) -> Sink._Private.MapError<E, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func flatMap<T, U>(_ adapt: @escaping (T) -> U) -> Sink._Private.FlatMap<T, U, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func buffer(_ count: Int) -> Sink._Private.Buffer<Self> {
        return .init(base: self, count: count)
    }

    @inlinable
    public func setFailureType<E>(to _: E.Type) -> Sink._Private.SetFailureType<E, Self> where Failure == Never {
        return .init(base: self)
    }
}

// MARK: - Handling Errors -

extension SinkProtocol {
    @inlinable
    public func assertNoError(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> Sink._Private.AssertNoError<Self> {
        return .init(base: self, prefix: prefix, file: file, line: line)
    }
}

// MARK: - Converting to Futures -

extension SinkProtocol {
    @inlinable
    public func sendAll<U>(_ stream: U, close: Bool = true) -> Sink._Private.SendAll<U, Self> {
        return .init(base: self, stream: stream, close: close)
    }

    @inlinable
    public func send(_ item: Input) -> Sink._Private.Send<Self> {
        return .init(base: self, item: item)
    }

    @inlinable
    public func flush() -> Sink._Private.Flush<Self> {
        return .init(base: self)
    }

    @inlinable
    public func close() -> Sink._Private.Close<Self> {
        return .init(base: self)
    }
}

// MARK: - Private -

/// :nodoc:
extension Sink {
    public enum _Private {}
}
