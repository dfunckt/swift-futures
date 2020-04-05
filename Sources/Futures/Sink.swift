//
//  Sink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public typealias SinkResult<Failure: Error> = Result<Void, Sink.Completion<Failure>>
public typealias PollSink<Failure: Error> = Poll<SinkResult<Failure>>

public protocol SinkProtocol: SinkConvertible where SinkType == Self {
    associatedtype Input
    associatedtype Failure: Error

    /// Send `item` into the sink.
    ///
    /// If this method signifies success, it is guaranteed that the item has
    /// been accepted and the sender may proceed to send another item.
    ///
    /// Note that this does not mean the item has been *observed* by whatever
    /// receiving end happens to be represented by the sink; sink implementations
    /// are free to buffer or otherwise delay delivery of the items as they
    /// see fit. To ensure a previously sent item has reached its destination,
    /// use `pollFlush(_:)`.
    ///
    /// Calling this method on a closed sink (see `pollClose(_:)`) fails with
    /// `Sink.Completion.closed`.
    ///
    /// - Returns:
    ///     - `Poll.pending`: The item could not immediately be accepted by
    ///         the sink; that is, the sink is applying back-pressure. Before
    ///         returning from this method, the sink will have arranged for
    ///         the sender to be notified when the operation can be retried.
    ///     - `Poll.ready(.success)`: The item was accepted by the sink.
    ///     - `Poll.ready(.failure(.closed))`: The operation failed because
    ///         the sink is closed.
    ///     - `Poll.ready(.failure(Failure))`: The operation failed due to an
    ///         error.
    mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure>

    /// Wait for the sink to flush its contents.
    ///
    /// `pollFlush(_:)` guarantees that all items sent by the *caller* before
    /// calling this method have been *observed* by the receiving end of sink.
    /// `pollFlush(_:)` therefore allows the sender to synchronize with the
    /// receiving end of the sink.
    ///
    /// Sink implementations are free to define what "observed by the
    /// receiving end" means; eg. for buffered sinks, this typically means
    /// that their buffer was drained.
    ///
    /// Calling this method on a closed sink (see `pollClose(_:)`) fails with
    /// `Sink.Completion.closed`.
    ///
    /// - Returns:
    ///     - `Poll.pending`: The sink still has items that its receiving
    ///         end has not yet observed. Before returning from this method,
    ///         the sink will have arranged for the sender to be notified when
    ///         the operation can be retried.
    ///     - `Poll.ready(.success)`: The receiving end of the sink observed
    ///         all previously sent items.
    ///     - `Poll.ready(.failure(.closed))`: The operation failed because
    ///         the sink is closed.
    ///     - `Poll.ready(.failure(Failure))`: The operation failed due to an
    ///         error.
    mutating func pollFlush(_ context: inout Context) -> PollSink<Failure>

    /// Close the sink, preventing further items to be sent, and wait for the
    /// sink to flush its contents.
    ///
    /// After the first call to this method, further calls to `pollSend(_:_:)`
    /// and `pollFlush(_:)` will fail with `Sink.Completion.closed`. This
    /// method may be called even after it returns `Poll.ready`.
    ///
    /// If this method signifies success, it is guaranteed that all items sent
    /// before calling this method have been observed by the receiving end of
    /// sink. See `pollFlush(_:)`.
    ///
    /// - Returns:
    ///     - `Poll.pending`: The sink closed successfully but still has items
    ///         that its receiving end has not yet observed. Before returning
    ///         from this method, the sink will have arranged for the sender
    ///         to be notified when the operation can be retried.
    ///     - `Poll.ready(.success)`: The sink closed successfully and the
    ///         receiving end of the sink observed all previously sent items.
    ///     - `Poll.ready(.failure(.closed))`: The sink closed successfully
    ///         but still has items that its receiving end will never receive
    ///         because itself went away.
    ///     - `Poll.ready(.failure(Failure))`: The sink closed successfully
    ///         but the operation caused an error.
    mutating func pollClose(_ context: inout Context) -> PollSink<Failure>
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
    @inline(__always)
    public func mapError<E: Error>(_ transform: (Failure) throws -> E) rethrows -> Sink.Completion<E> {
        switch self {
        case .closed:
            return .closed
        case .failure(let error):
            return try .failure(transform(error))
        }
    }
}

extension Poll {
    @inlinable
    @inline(__always)
    public func map<E: Error>(_ onSuccess: () -> SinkResult<E>) -> Poll where T == SinkResult<E> {
        switch self {
        case .ready(.success):
            return .ready(onSuccess())
        case .ready(.failure(let error)):
            return .ready(.failure(error))
        case .pending:
            return .pending
        }
    }

    @inlinable
    @inline(__always)
    public func mapError<E: Error, NewFailure: Error>(_ onFailure: (E) -> SinkResult<NewFailure>) -> PollSink<NewFailure> where T == SinkResult<E> {
        switch self {
        case .ready(.success):
            return .ready(.success(()))
        case .ready(.failure(.closed)):
            return .ready(.failure(.closed))
        case .ready(.failure(.failure(let error))):
            return .ready(onFailure(error))
        case .pending:
            return .pending
        }
    }

    @inlinable
    @inline(__always)
    public func flatMap<E: Error>(_ onSuccess: () -> Poll) -> Poll where T == SinkResult<E> {
        switch self {
        case .ready(.success):
            return onSuccess()
        case .ready(.failure(let error)):
            return .ready(.failure(error))
        case .pending:
            return .pending
        }
    }

    @inlinable
    @inline(__always)
    public func flatMapError<E: Error, NewFailure: Error>(_ onFailure: (E) -> PollSink<NewFailure>) -> PollSink<NewFailure> where T == SinkResult<E> {
        switch self {
        case .ready(.success):
            return .ready(.success(()))
        case .ready(.failure(.closed)):
            return .ready(.failure(.closed))
        case .ready(.failure(.failure(let error))):
            return onFailure(error)
        case .pending:
            return .pending
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
    public typealias PollSendFn = (inout Context, Input) -> PollSink<Failure>
    public typealias PollFlushFn = (inout Context) -> PollSink<Failure>
    public typealias PollCloseFn = (inout Context) -> PollSink<Failure>

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
    public func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
        return _pollSend(&context, item)
    }

    @inlinable
    public func pollFlush(_ context: inout Context) -> PollSink<Failure> {
        return _pollFlush(&context)
    }

    @inlinable
    public func pollClose(_ context: inout Context) -> PollSink<Failure> {
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
    public func mapInput<T>(_ adapt: @escaping (T) -> Input) -> Sink._Private.MapInput<T, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func flatMapInput<T, U>(_ adapt: @escaping (T) -> U) -> Sink._Private.FlatMapInput<T, U, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func buffer(_ count: Int) -> Sink._Private.Buffer<Self> {
        return .init(base: self, count: count)
    }
}

// MARK: - Handling Errors -

extension SinkProtocol {
    @inlinable
    public func mapError<E>(_ adapt: @escaping (Error) -> E) -> Sink._Private.MapError<E, Self> {
        return .init(base: self, adapt: adapt)
    }

    @inlinable
    public func setFailureType<E>(to _: E.Type) -> Sink._Private.SetFailureType<E, Self> where Failure == Never {
        return .init(base: self)
    }

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
