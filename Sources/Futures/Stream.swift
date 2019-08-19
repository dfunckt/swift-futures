//
//  Stream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol that defines an abstraction for a series of asynchronously
/// produced discrete values over time, such as byte buffers read from a
/// socket or a file, incoming requests to a server, or sampled mouse input
/// events.
///
/// Streams *yield* elements. Similar to Swift's `IteratorProtocol`, streams
/// signify completion by yielding `nil`. Streams can be combined into larger
/// operations with *combinators*, such as `map()`, `flatMap()`, etc.
///
/// The type of element yielded by a stream is specified by its `Output` type.
/// Streams that must communicate success or failure, must do so by encoding
/// that information in the output type, typically using `Swift.Result`.
/// Futures comes with a number of convenience types and combinators for
/// working with `Swift.Result` (see `FuturesResult` module).
///
/// You typically create streams using the convenience methods on `Stream`.
/// You can also create custom streams by adopting this protocol in your
/// types. Creating streams is *always* an asynchronous operation. It is
/// guaranteed that the producer of elements the stream wraps will only be
/// asked for elements after the stream is submitted to an executor and it
/// will always be on that executor's context (see `ExecutorProtocol`). In
/// other words, streams do nothing unless submitted to an executor.
///
/// For a stream to be submitted to an executor and yield elements, it must
/// be converted to a future that represents the stream's completion. As a
/// convenience, this is done automatically if the stream output is `Void`.
///
/// The semantics for cancellation, and memory and concurrency management
/// are the same as for futures (see `FutureProtocol`).
public protocol StreamProtocol: StreamConvertible where StreamType == Self {
    associatedtype Output
    mutating func pollNext(_ context: inout Context) -> Poll<Output?>
}

public protocol StreamConvertible {
    associatedtype StreamType: StreamProtocol
    nonmutating func makeStream() -> StreamType
}

/// A namespace for types and convenience methods related to streams.
///
/// For details on streams, see `StreamProtocol`.
public enum Stream {}

// MARK: - Supporting Types -

extension Stream {
    public enum ReplayStrategy {
        case none
        case latest
        case last(Int)
        case all
    }
}

// MARK: - Creating Streams -

/// A type-erasing stream.
///
/// Use `AnyStream` to wrap a stream whose type has details you don’t want to
/// expose. This is typically the case when returning streams from a function
/// or storing streams in properties.
///
/// You can also use `AnyStream` to create a custom stream by providing a
/// closure for the `pollNext` method, rather than implementing `StreamProtocol`
/// directly on a custom type.
public struct AnyStream<Output>: StreamProtocol {
    public typealias PollNextFn = (inout Context) -> Poll<Output?>

    @usableFromInline let _pollNextFn: PollNextFn

    /// Creates a type-erasing stream implemented by the provided closure.
    ///
    ///     var iter = (0..<3).makeIterator()
    ///     var s = AnyStream { _ in
    ///         Poll.ready(iter.next())
    ///     }
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    @inlinable
    public init(_ pollNext: @escaping PollNextFn) {
        _pollNextFn = pollNext
    }

    /// Creates a type-erasing stream to wrap the provided stream.
    ///
    /// This initializer performs a heap allocation unless the wrapped stream
    /// is already type-erased.
    @inlinable
    public init<S: StreamProtocol>(_ stream: S) where S.Output == Output {
        if let s = stream as? AnyStream {
            _pollNextFn = s._pollNextFn
        } else {
            var s = stream
            _pollNextFn = {
                s.pollNext(&$0)
            }
        }
    }

    @inlinable
    public func pollNext(_ context: inout Context) -> Poll<Output?> {
        return _pollNextFn(&context)
    }
}

/// A type-erasing multicast stream.
///
/// Multicast streams can yield their output to more than one receiver.
public struct AnyMulticastStream<Output>: StreamConvertible {
    @usableFromInline let _makeStream: () -> AnyStream<Output>

    @inlinable
    public init<S: StreamProtocol>(_ base: Stream._Private.Multicast<S>) where S.Output == Output {
        _makeStream = { base.makeStream().eraseToAnyStream() }
    }

    @inlinable
    public init<S: StreamProtocol>(_ base: Stream._Private.Share<S>) where S.Output == Output {
        _makeStream = { base.makeStream().eraseToAnyStream() }
    }

    @inlinable
    public func makeStream() -> AnyStream<Output> {
        return _makeStream()
    }
}

/// A type-erasing shared stream.
///
/// Shared streams can yield their output to more than one receiver and are
/// safe to use from multiple tasks concurrently.
public struct AnySharedStream<Output>: StreamConvertible {
    @usableFromInline let _makeStream: () -> AnyStream<Output>

    @inlinable
    public init<S: StreamProtocol>(_ base: Stream._Private.Share<S>) where S.Output == Output {
        _makeStream = { base.makeStream().eraseToAnyStream() }
    }

    @inlinable
    public func makeStream() -> AnyStream<Output> {
        return _makeStream()
    }
}

extension Stream {
    /// Creates a stream that yields no elements and never completes.
    ///
    ///     var s = Stream.never(outputType: Void.self)
    ///     s.next() // Will block forever
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func never<T>(outputType _: T.Type = T.self) -> Stream._Private.Never<T> {
        return .init()
    }

    /// Creates a stream that yields no elements and immediately completes.
    ///
    ///     var s = Stream.empty(outputType: Void.self)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func empty<T>(outputType _: T.Type = T.self) -> Stream._Private.Empty<T> {
        return .init()
    }

    /// Creates a stream that yields zero or one element, depending on whether
    /// the provided optional is `nil`, and completes.
    ///
    ///     let someInt: Int? = 42
    ///     var s = Stream.optional(someInt)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == nil)
    ///
    ///     let noInt: Int? = nil
    ///     var s = Stream.optional(noInt)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    // swiftformat:disable:next typeSugar
    public static func optional<T>(_ value: T?) -> Stream._Private.Optional<T> {
        return .init(value: value)
    }

    /// Creates a stream that yields the provided element and completes.
    ///
    ///     var s = Stream.just(42)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func just<T>(_ element: T) -> Stream._Private.Just<T> {
        return .init(element: element)
    }

    /// Creates a stream that repeatedly yields the provided element and never
    /// completes.
    ///
    ///     var s = Stream.repeat(42)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == 42)
    ///     // ...
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func `repeat`<T>(_ element: T) -> Stream._Private.Repeat<T> {
        return .init(element: element)
    }

    /// Creates a stream the yields the elements of the provided sequence and
    /// completes.
    ///
    ///     var s = Stream.sequence(0..<3)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == C.Element>`
    @inlinable
    public static func sequence<C>(_ elements: C) -> Stream._Private.Sequence<C> {
        return .init(sequence: elements)
    }

    /// Creates a stream that yields the elements of the sequence formed from
    /// `first` and the results of repeated lazy applications of `next`.
    ///
    /// The first element yielded by the stream is always `first`, and each
    /// successive element is the result of invoking `next` with the previous
    /// element. The stream ends when `next` returns `nil`. If `next` never
    /// returns `nil`, the stream is infinite.
    ///
    ///     var s = Stream.generate(first: 1) {
    ///         $0 < 3 ? $0 + 1 : nil
    ///     }
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func generate<T>(first: T, _ next: @escaping (T) -> T?) -> Stream._Private.Generate<T> {
        return .init(first: first, next: next)
    }

    /// Creates a stream that yields the elements of the sequence formed from
    /// `initial` and the results of the futures returned by repeated lazy
    /// applications of `next`.
    ///
    /// The first element yielded by the stream is always `initial`, and each
    /// successive element is the output of the future returned by invoking
    /// `next` with the previous element. The stream ends when `next` returns
    /// `nil`. If `next` never returns `nil`, the sequence is infinite.
    ///
    ///     var s = Stream.unfold(initial: 1) {
    ///         $0 < 3 ? Future.ready($0 + 1) : nil
    ///     }
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public static func unfold<T, U>(initial: T, _ next: @escaping (T) -> U?) -> Stream._Private.Unfold<U> where T == U.FutureType.Output {
        return .init(initial: initial, next: next)
    }

    /// Creates a stream that lazily invokes the given closure and yields the
    /// elements from the returned stream.
    ///
    ///     var s = Stream.lazy {
    ///         Stream.sequence(0..<3)
    ///     }
    ///     assert(s.wait() == 0)
    ///     assert(s.wait() == 1)
    ///     assert(s.wait() == 2)
    ///     assert(s.wait() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == U.StreamType.Output>`
    @inlinable
    public static func `lazy`<U>(_ body: @escaping () -> U) -> Stream._Private.Lazy<U> {
        return .init(body)
    }
}

// MARK: - Instance Methods -

extension StreamProtocol {
    /// Returns a future that will complete with a 2-tuple containing the next
    /// element from this stream and the stream itself.
    ///
    ///     var output: Int?
    ///     var s = Stream.sequence(0..<3)
    ///
    ///     (output, s) = s.makeFuture().wait()
    ///     assert(output == 0)
    ///
    ///     (output, s) = s.makeFuture().wait()
    ///     assert(output == 1)
    ///
    ///     (output, s) = s.makeFuture().wait()
    ///     assert(output == 2)
    ///
    ///     (output, s) = s.makeFuture().wait()
    ///     assert(output == nil)
    ///
    /// - Returns: `some FutureProtocol<Output == (Self.Output?, Self)>`
    @inlinable
    public func makeFuture() -> Stream._Private.Future<Self> {
        return .init(base: self)
    }

    /// .
    ///
    ///     var s = Stream.sequence(0..<3).makeStream()
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @_transparent
    public func makeStream() -> Self {
        return self
    }

    /// .
    ///
    ///     var s1 = Stream.sequence(0..<3).makeReference()
    ///     var s2 = Stream.sequence(3..<6).makeReference()
    ///     var s = Stream.join(s1, s2)
    ///     assert(s.next()! == (0, 3))
    ///     assert(s1.next() == 1)
    ///     assert(s2.next() == 4)
    ///     assert(s.next()! == (2, 5))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func makeReference() -> Stream._Private.Reference<Self> {
        return .init(base: self)
    }

    /// Synchronously polls this stream on the current thread's executor until
    /// it yields the next element or completes.
    ///
    ///     var s = Stream.sequence(0..<3)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `Self.Output?`
    @inlinable
    public mutating func next() -> Output? {
        return next(on: ThreadExecutor.current)
    }

    /// Synchronously polls this stream using the provided blocking executor
    /// until it yields the next element or completes.
    ///
    ///     let executor = ThreadExecutor.current
    ///     var s = Stream.sequence(0..<3)
    ///     assert(s.next(on: executor) == 0)
    ///     assert(s.next(on: executor) == 1)
    ///     assert(s.next(on: executor) == 2)
    ///     assert(s.next(on: executor) == nil)
    ///
    /// - Returns: `Self.Output?`
    @inlinable
    public mutating func next<E: BlockingExecutor>(on executor: E) -> Output? {
        let result = makeFuture().wait(on: executor)
        self = result.stream
        return result.output
    }

    /// .
    ///
    ///     let sink = Sink.collect(itemType: Int.self)
    ///     let f = Stream.sequence(0..<3).forward(to: sink)
    ///     f.ignoreOutput().wait()
    ///     assert(sink.elements == [0, 1, 2])
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Void, S.Failure>>`
    @inlinable
    public func forward<S>(to sink: S, close: Bool = true) -> Stream._Private.Forward<S, Self> {
        return .init(base: self, sink: sink, close: close)
    }

    // TODO: assign
    // TODO: sink

    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func abort<U>(when f: U) -> Stream._Private.Abort<U, Self> {
        return .init(base: self, signal: { f })
    }

    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func abort<U>(when f: @escaping () -> U) -> Stream._Private.Abort<U, Self> {
        return .init(base: self, signal: f)
    }

    /// Ensures this stream is polled on the given executor.
    ///
    /// The returned stream retains the executor for its whole lifetime.
    ///
    ///     var s = Stream.sequence(0..<3)
    ///         .poll(on: QueueExecutor.global)
    ///         .assertNoError()
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<Self.Output, E.Failure>>`
    @inlinable
    public func poll<E: ExecutorProtocol>(on executor: E) -> Stream._Private.PollOn<E, Self> {
        return .init(base: self, executor: executor)
    }

    /// - Precondition: `maxElements > 0`
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func yield(maxElements: Int) -> Stream._Private.Yield<Self> {
        return .init(base: self, maxElements: maxElements)
    }
}

// MARK: - Vending Streams -

extension StreamProtocol {
    /// .
    ///
    ///     var s = Stream.sequence(0..<3).eraseToAnyStream()
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `AnyStream<Self.Output>`
    @inlinable
    public func eraseToAnyStream() -> AnyStream<Output> {
        return .init(self)
    }
}

// MARK: -

extension StreamProtocol {
    /// Multicasts elements from this stream to multiple tasks, where each
    /// task sees every element, that run on the same executor.
    ///
    /// Use this combinator when you want to use reference semantics, such as
    /// storing a stream instance in a property.
    ///
    ///     let iterations = 1_000
    ///     var counter0 = 0
    ///     var counter1 = 0
    ///     var counter2 = 0
    ///
    ///     let stream = Stream.sequence(0..<iterations).forEach {
    ///         counter0 += $0
    ///     }
    ///
    ///     let multicast = stream.multicast()
    ///     let stream1 = multicast.makeStream().map { counter1 += $0 }
    ///     let stream2 = multicast.makeStream().map { counter2 += $0 }
    ///
    ///     ThreadExecutor.current.submit(stream1)
    ///     ThreadExecutor.current.submit(stream2)
    ///     ThreadExecutor.current.wait()
    ///
    ///     let expected = (0..<iterations).reduce(into: 0, +=)
    ///     assert(counter0 == expected) // 499_500
    ///     assert(counter1 == expected)
    ///     assert(counter2 == expected)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func multicast(replay: Stream.ReplayStrategy = .none) -> Stream._Private.Multicast<Self> {
        return .init(base: self, replay: replay)
    }

    /// - Returns: `AnyMulticastStream<Self.Output>`
    @inlinable
    public func eraseToAnyMulticastStream(replay: Stream.ReplayStrategy = .none) -> AnyMulticastStream<Output> {
        return multicast(replay: replay).eraseToAnyMulticastStream()
    }
}

// MARK: -

extension StreamProtocol {
    /// Multicasts elements from this stream to multiple tasks, where each
    /// task sees every element, that may run on any executor.
    ///
    /// Use this combinator when you want to use reference semantics, such as
    /// storing a stream instance in a property.
    ///
    ///     let iterations = 1_000
    ///     var counter0 = 0
    ///     var counter1 = 0
    ///     var counter2 = 0
    ///
    ///     let stream = Stream.sequence(0..<iterations).forEach {
    ///         counter0 += $0
    ///     }
    ///
    ///     let shared = stream.share()
    ///     let stream1 = shared.makeStream().map { counter1 += $0 }
    ///     let stream2 = shared.makeStream().map { counter2 += $0 }
    ///
    ///     let task1 = QueueExecutor(label: "queue 1").spawn(stream1)
    ///     let task2 = QueueExecutor(label: "queue 2").spawn(stream2)
    ///
    ///     ThreadExecutor.current.submit(task1)
    ///     ThreadExecutor.current.submit(task2)
    ///     ThreadExecutor.current.wait()
    ///
    ///     let expected = (0..<iterations).reduce(into: 0, +=)
    ///     assert(counter0 == expected) // 499_500
    ///     assert(counter1 == expected)
    ///     assert(counter2 == expected)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func share(replay: Stream.ReplayStrategy = .none) -> Stream._Private.Share<Self> {
        return .init(base: self, replay: replay)
    }

    /// - Returns: `AnySharedStream<Self.Output>`
    @inlinable
    public func eraseToAnySharedStream(replay: Stream.ReplayStrategy = .none) -> AnySharedStream<Output> {
        return share(replay: replay).eraseToAnySharedStream()
    }
}

// MARK: - Mapping Elements -

extension StreamProtocol {
    /// Transforms all elements from this stream with a provided closure.
    ///
    ///     var s = Stream.sequence(0..<3).map {
    ///         $0 + 1
    ///     }
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func map<T>(_ transform: @escaping (Output) -> T) -> Stream._Private.Map<T, Self> {
        return .init(base: self, transform: transform)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a: Int
    ///     }
    ///     let data: [Data] = [
    ///         .init(a: 0),
    ///         .init(a: 3),
    ///         .init(a: 6),
    ///     ]
    ///     var s = Stream.sequence(data).map(\.a)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func map<T>(_ keyPath: KeyPath<Output, T>) -> Stream._Private.MapKeyPath<T, Self> {
        return .init(base: self, keyPath: keyPath)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a, b: Int
    ///     }
    ///     let data: [Data] = [
    ///         .init(a: 0, b: 1),
    ///         .init(a: 3, b: 4),
    ///         .init(a: 6, b: 7),
    ///     ]
    ///     var s = Stream.sequence(data).map(\.a, \.b)
    ///     assert(s.next() == (0, 1))
    ///     assert(s.next() == (3, 4))
    ///     assert(s.next() == (6, 7))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (T0, T1)>`
    @inlinable
    public func map<T0, T1>(_ keyPath0: KeyPath<Output, T0>, _ keyPath1: KeyPath<Output, T1>) -> Stream._Private.MapKeyPath2<T0, T1, Self> {
        return .init(base: self, keyPath0: keyPath0, keyPath1: keyPath1)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a, b, c: Int
    ///     }
    ///     let data: [Data] = [
    ///         .init(a: 0, b: 1, c: 2),
    ///         .init(a: 3, b: 4, c: 5),
    ///         .init(a: 6, b: 7, c: 8),
    ///     ]
    ///     var s = Stream.sequence(data).map(\.a, \.b, \.c)
    ///     assert(s.next() == (0, 1, 2))
    ///     assert(s.next() == (3, 4, 5))
    ///     assert(s.next() == (6, 7, 8))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (T0, T1, T2)>`
    @inlinable
    public func map<T0, T1, T2>(_ keyPath0: KeyPath<Output, T0>, _ keyPath1: KeyPath<Output, T1>, _ keyPath2: KeyPath<Output, T2>) -> Stream._Private.MapKeyPath3<T0, T1, T2, Self> {
        return .init(base: self, keyPath0: keyPath0, keyPath1: keyPath1, keyPath2: keyPath2)
    }

    /// Transforms each element from this stream into a new stream using a
    /// provided closure and merges the output from all returned streams into
    /// a single stream of output.
    ///
    ///     var s = Stream.sequence(0..<3).flatMap {
    ///         Stream.sequence(0...($0 + 1))
    ///     }
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == U.StreamType.Output>`
    @inlinable
    public func flatMap<U>(_ transform: @escaping (Output) -> U) -> Stream._Private.FlatMap<U, Self> {
        return .init(base: self, transform: transform)
    }

    // TODO: then(on:)

    /// Transforms elements from this stream by providing the current element
    /// to a closure along with the last value returned by the closure.
    ///
    ///     var s = Stream.sequence(0..<3).scan(0) {
    ///         $0 + $1
    ///     }
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func scan<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) -> T) -> Stream._Private.Scan<T, Self> {
        return .init(base: self, initialResult: initialResult, nextPartialResult: nextPartialResult)
    }

    /// Replaces nil elements in the stream with the provided element.
    ///
    ///     var s = Stream.sequence([0, nil, 2]).replaceNil(with: 1)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func replaceNil<T>(with output: T) -> Stream._Private.Map<T, Self> where Output == T? {
        return .init(replacingNilFrom: self, with: output)
    }
}

// MARK: -

extension StreamProtocol where Output: _OptionalConvertible {
    /// .
    ///
    ///     var s = Stream.sequence([0, nil, 2]).match(
    ///         some: String.init,
    ///         none: { "NaN" }
    ///     )
    ///     assert(s.next() == "0")
    ///     assert(s.next() == "NaN")
    ///     assert(s.next() == "2")
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func match<T>(
        some: @escaping (Output.WrappedType) -> T,
        none: @escaping () -> T
    ) -> Stream._Private.MatchOptional<T, Self> {
        return .init(base: self, some: some, none: none)
    }
}

// MARK: -

extension StreamProtocol where Output: EitherConvertible {
    /// .
    ///
    ///     func transform(_ value: Int) -> Either<Int, Float> {
    ///         if value == 0 {
    ///             return .left(value)
    ///         } else {
    ///             return .right(.init(value))
    ///         }
    ///     }
    ///     var s = Stream.sequence(0..<3).map(transform).match(
    ///         left: String.init,
    ///         right: String.init(describing:)
    ///     )
    ///     assert(s.next() == "0")
    ///     assert(s.next() == "1.0")
    ///     assert(s.next() == "2.0")
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func match<T>(
        left: @escaping (Output.Left) -> T,
        right: @escaping (Output.Right) -> T
    ) -> Stream._Private.MatchEither<T, Self> {
        return .init(base: self, left: left, right: right)
    }
}

// MARK: - Filtering Elements -

extension StreamProtocol {
    /// Yields all elements that match a provided closure.
    ///
    ///     var s = Stream.sequence(0..<3).filter {
    ///         $0 > 0
    ///     }
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func filter(_ isIncluded: @escaping (Output) -> Bool) -> Stream._Private.Filter<Self> {
        return .init(base: self, isIncluded: isIncluded)
    }

    /// Calls a closure with each element from this stream and yields any
    /// returned optional that has a value.
    ///
    ///     var s = Stream.sequence(0..<3).compactMap {
    ///         $0 > 0 ? $0 * 2 : nil
    ///     }
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func compactMap<T>(_ transform: @escaping (Output) -> T?) -> Stream._Private.CompactMap<T, Self> {
        return .init(base: self, transform: transform)
    }

    /// Replaces an empty stream with the provided element.
    ///
    /// If this stream completes without yielding any elements, the returned
    /// stream yields the provided element, then completes normally.
    ///
    ///     var s = Stream.empty().replaceEmpty(with: 42)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func replaceEmpty(with output: Output) -> Stream._Private.ReplaceEmpty<Self> {
        return .init(base: self, output: output)
    }

    /// Calls a predicate closure with two consecutive elements from this
    /// stream and yields the current element if it passes the predicate.
    ///
    ///     let data = [
    ///         (1, "A"),
    ///         (2, "B"),
    ///         (3, "B"),
    ///         (4, "C"),
    ///     ]
    ///     var s = Stream.sequence(data).removeDuplicates {
    ///         $0.1 == $1.1
    ///     }
    ///     assert(s.next()! == (1, "A"))
    ///     assert(s.next()! == (2, "B"))
    ///     assert(s.next()! == (4, "C"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func removeDuplicates(by predicate: @escaping (Output, Output) -> Bool) -> Stream._Private.RemoveDuplicates<Self> {
        return .init(base: self, predicate: predicate)
    }
}

// MARK: -

extension StreamProtocol where Output: Equatable {
    /// Yields only elements that don’t match the previous element.
    ///
    ///     var s = Stream.sequence([1, 2, 2, 2, 3]).removeDuplicates()
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func removeDuplicates() -> Stream._Private.RemoveDuplicates<Self> {
        return .init(base: self)
    }
}

// MARK: - Reducing Elements -

extension StreamProtocol {
    /// Returns a future that collects all elements from this stream, and
    /// completes with a single array of the collection when it completes.
    ///
    /// This combinator uses an unbounded amount of memory to store the
    /// yielded values.
    ///
    ///     let f = Stream.sequence(0..<3).collect()
    ///     assert(f.wait() == [0, 1, 2])
    ///
    /// - Returns: `some FutureProtocol<Output == [Self.Output]>`
    @inlinable
    public func collect() -> Stream._Private.ReduceInto<[Output], Self> {
        return .init(collectingOutputFrom: self)
    }

    /// Returns a future that ignores all elements from this stream, and
    /// completes with a given value when this stream completes.
    ///
    ///     let f = Stream.sequence(0..<3).replaceOutput(with: 42)
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func replaceOutput<T>(with output: T) -> Stream._Private.Reduce<T, Self> {
        return .init(replacingOutputFrom: self, with: output)
    }

    /// Returns a future that ignores all elements from this stream, and
    /// completes when this stream completes.
    ///
    ///     let f = Stream.sequence(0..<3).ignoreOutput()
    ///     assert(f.wait() == ())
    ///
    /// - Returns: `some FutureProtocol<Output == Void>`
    @inlinable
    public func ignoreOutput() -> Stream._Private.Reduce<Void, Self> {
        return .init(ignoringOutputFrom: self)
    }

    /// Returns a future that completes with the number of elements from this
    /// stream.
    ///
    ///     let f = Stream.sequence(0..<3).count()
    ///     assert(f.wait() == 3)
    ///
    /// - Returns: `some FutureProtocol<Output == Int>`
    @inlinable
    public func count() -> Stream._Private.Reduce<Int, Self> {
        return .init(countingElementsFrom: self)
    }

    /// Returns a future that applies a closure that accumulates each element
    /// of this stream and completes with the final result when this stream
    /// completes.
    ///
    ///     let f = Stream.sequence(0..<3).reduce(0) {
    ///         $0 + $1
    ///     }
    ///     assert(f.wait() == 3)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func reduce<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, Output) -> T) -> Stream._Private.Reduce<T, Self> {
        return .init(base: self, initialResult: initialResult, nextPartialResult: nextPartialResult)
    }

    /// Returns a future that applies a closure that combines each element of
    /// this stream into a mutable state and completes with the final result
    /// when this stream completes.
    ///
    ///     let f = Stream.sequence(0..<3).reduce(into: []) {
    ///         $0.append($1 + 1)
    ///     }
    ///     assert(f.wait() == [1, 2, 3])
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func reduce<T>(into state: T, _ reducer: @escaping (inout T, Output) -> Void) -> Stream._Private.ReduceInto<T, Self> {
        return .init(base: self, state: state, reducer: reducer)
    }
}

// MARK: - Applying Matching Criteria to Elements -

extension StreamProtocol where Output: Equatable {
    /// Returns a future that completes with a Boolean value upon receiving an
    /// element equal to the argument.
    ///
    ///     let f = Stream.sequence(0..<3).contains(2)
    ///     assert(f.wait())
    ///
    /// - Returns: `some FutureProtocol<Output == Bool>`
    @inlinable
    public func contains(_ output: Output) -> Stream._Private.Contains<Self> {
        return .init(base: self, output: output)
    }
}

// MARK: -

extension StreamProtocol {
    /// Returns a future that completes with a Boolean value upon receiving an
    /// element that satisfies the predicate closure.
    ///
    ///     let f = Stream.sequence(0..<3).contains {
    ///         $0 == 2
    ///     }
    ///     assert(f.wait())
    ///
    /// - Returns: `some FutureProtocol<Output == Bool>`
    @inlinable
    public func contains(where predicate: @escaping (Output) -> Bool) -> Stream._Private.ContainsWhere<Self> {
        return .init(base: self, predicate: predicate)
    }

    /// Returns a future that completes with a Boolean value that indicates
    /// whether all received elements pass a given predicate.
    ///
    ///     let f = Stream.sequence(0..<3).allSatisfy {
    ///         $0 < 3
    ///     }
    ///     assert(f.wait())
    ///
    /// - Returns: `some FutureProtocol<Output == Bool>`
    @inlinable
    public func allSatisfy(_ predicate: @escaping (Output) -> Bool) -> Stream._Private.AllSatisfy<Self> {
        return .init(base: self, predicate: predicate)
    }
}

// MARK: - Applying Sequence Operations to Elements -

extension StreamProtocol {
    /// Ignores elements from this stream until the given future completes.
    ///
    ///     var pollCount = 0
    ///     let f = AnyFuture<Void> { _ in
    ///         if pollCount == 2 {
    ///             return .ready(())
    ///         }
    ///         pollCount += 1
    ///         return .pending
    ///     }
    ///     var s = Stream.sequence(0..<3).drop(untilOutputFrom: f)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func drop<F>(untilOutputFrom future: F) -> Stream._Private.DropUntilOutput<F, Self> {
        return .init(base: self, future: future)
    }

    /// Omits elements from this stream until a given closure returns `false`,
    /// before yielding all remaining elements.
    ///
    ///     var s = Stream.sequence(0..<3).drop(while: { $0 < 2 })
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func drop(while predicate: @escaping (Output) -> Bool) -> Stream._Private.DropWhile<Self> {
        return .init(base: self, predicate: predicate)
    }

    /// Omits the specified number of elements before yielding subsequent
    /// elements.
    ///
    ///     var s = Stream.sequence(0..<3).dropFirst(2)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func dropFirst(_ count: Int = 1) -> Stream._Private.Drop<Self> {
        return .init(base: self, count: count)
    }

    /// Appends the specified elements to this stream's output.
    ///
    ///     var s = Stream.sequence(0..<3).append(3, 4, 5)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func append(_ elements: Output...) -> Stream._Private.Concatenate<Self, Stream._Private.Sequence<[Output]>> {
        return .init(prefix: self, suffix: .init(sequence: elements))
    }

    /// Appends a specified sequence to this stream's output.
    ///
    ///     var s = Stream.sequence(0..<3).append(3..<6)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func append<C: Sequence>(_ elements: C) -> Stream._Private.Concatenate<Self, Stream._Private.Sequence<C>> where Output == C.Element {
        return .init(prefix: self, suffix: .init(sequence: elements))
    }

    /// Appends the elements from the given stream to this stream's output.
    ///
    ///     let a = Stream.sequence(3..<6)
    ///     var s = Stream.sequence(0..<3).append(a)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func append<S: StreamProtocol>(_ stream: S) -> Stream._Private.Concatenate<Self, S> {
        return .init(prefix: self, suffix: stream)
    }

    /// Prepends the specified elements to this stream's output.
    ///
    ///     var s = Stream.sequence(0..<3).prepend(3, 4, 5)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prepend(_ elements: Output...) -> Stream._Private.Concatenate<Stream._Private.Sequence<[Output]>, Self> {
        return .init(prefix: .init(sequence: elements), suffix: self)
    }

    /// Prepends a specified sequence to this stream's output.
    ///
    ///     var s = Stream.sequence(0..<3).prepend(3..<6)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prepend<S: Sequence>(_ elements: S) -> Stream._Private.Concatenate<Stream._Private.Sequence<S>, Self> where Output == S.Element {
        return .init(prefix: .init(sequence: elements), suffix: self)
    }

    /// Prepends the elements from the given stream to this stream's output.
    ///
    ///     let a = Stream.sequence(3..<6)
    ///     var s = Stream.sequence(0..<3).prepend(a)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prepend<S: StreamProtocol>(_ stream: S) -> Stream._Private.Concatenate<S, Self> {
        return .init(prefix: stream, suffix: self)
    }

    /// Yields elements from this stream until the given future completes.
    ///
    ///     var pollCount = 0
    ///     let f = AnyFuture<Void> { _ in
    ///         if pollCount == 2 {
    ///             return .ready(())
    ///         }
    ///         pollCount += 1
    ///         return .pending
    ///     }
    ///     var s = Stream.sequence(0..<3).prefix(untilOutputFrom: f)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prefix<F>(untilOutputFrom future: F) -> Stream._Private.PrefixUntilOutput<F, Self> {
        return .init(base: self, future: future)
    }

    /// Yields elements from this stream up to the specified maximum count.
    ///
    ///     var s = Stream.sequence(0..<3).prefix(2)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prefix(_ maxLength: Int) -> Stream._Private.Prefix<Self> {
        return .init(base: self, maxLength: maxLength)
    }

    /// Yields elements from this stream while elements satisfy a predicate
    /// closure.
    ///
    ///     var s = Stream.sequence(0..<3).prefix(while: { $0 < 2 })
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func prefix(while predicate: @escaping (Output) -> Bool) -> Stream._Private.PrefixWhile<Self> {
        return .init(base: self, predicate: predicate)
    }

    /// Collects up to the specified number of elements, and then yields a
    /// single array of the collection.
    ///
    ///     var s = Stream.sequence(0...4).buffer(2)
    ///     assert(s.next() == [0, 1])
    ///     assert(s.next() == [2, 3])
    ///     assert(s.next() == [4])
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == [Self.Output]>`
    @inlinable
    public func buffer(_ count: Int) -> Stream._Private.Buffer<Self> {
        return .init(base: self, count: count)
    }

    /// Applies the given closure over each element from this stream.
    ///
    ///     var buffer = [Int]()
    ///     var s = Stream.sequence(0..<3).forEach {
    ///         buffer.append($0)
    ///     }
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///     assert(buffer == [0, 1, 2])
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func forEach(_ body: @escaping (Output) -> Void) -> Stream._Private.ForEach<Self> {
        return .init(base: self, inspect: body)
    }

    /// Yields pairs *(n, x)*, where *n* represents a consecutive integer
    /// starting at zero and *x* represents an element from this stream.
    ///
    ///     var s = Stream.sequence(["A", "B", "C"]).enumerate()
    ///     assert(s.next()! == (offset: 0, output: "A"))
    ///     assert(s.next()! == (offset: 1, output: "B"))
    ///     assert(s.next()! == (offset: 2, output: "C"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Int, Self.Output)>`
    @inlinable
    public func enumerate() -> Stream._Private.Enumerate<Self> {
        return .init(base: self)
    }
}

// MARK: - Selecting Specific Elements -

extension StreamProtocol {
    /// Returns a future that completes with the first element from this stream.
    ///
    ///     let f = Stream.sequence(0..<3).first()
    ///     assert(f.wait() == 0)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func first() -> Stream._Private.First<Self> {
        return .init(base: self)
    }

    /// Returns a future that completes with the first element from this stream
    /// to satisfy a predicate closure.
    ///
    ///     let f = Stream.sequence(0..<3).first(where: { $0 > 1 })
    ///     assert(f.wait() == 2)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func first(where predicate: @escaping (Output) -> Bool) -> Stream._Private.FirstWhere<Self> {
        return .init(base: self, predicate: predicate)
    }

    /// Returns a future that completes with the last element from this stream.
    ///
    ///     let f = Stream.sequence(0..<3).last()
    ///     assert(f.wait() == 2)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func last() -> Stream._Private.Last<Self> {
        return .init(base: self)
    }

    /// Returns a future that completes with the last element from this stream
    /// to satisfy a predicate closure.
    ///
    ///     let f = Stream.sequence(0..<3).last(where: { $0 < 2 })
    ///     assert(f.wait() == 1)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func last(where predicate: @escaping (Output) -> Bool) -> Stream._Private.LastWhere<Self> {
        return .init(base: self, predicate: predicate)
    }

    /// Yields a specific element from this stream, indicated by its index in
    /// the sequence of yielded elements.
    ///
    ///     var s = Stream.sequence(0..<3).output(at: 1)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func output(at index: Int) -> Stream._Private.Output<Self> {
        return .init(base: self, range: index..<(index + 1))
    }

    /// Yields elements from this stream specified by their range in the
    /// sequence of yielded elements.
    ///
    ///     var s = Stream.sequence(0..<3).output(in: 1..<3)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func output<R: RangeExpression>(in range: R) -> Stream._Private.Output<Self> where R.Bound == Int {
        return .init(base: self, range: range.relative(to: 0..<Int.max))
    }

    /// Yields the latest available element by eagerly pulling elements out of
    /// this stream until it can't yield any more elements.
    ///
    ///     var s = Stream.sequence(0..<3).latest()
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func latest() -> Stream._Private.Latest<Self> {
        return .init(base: self)
    }
}

// MARK: - Combining Output from Multiple Streams -

extension Stream {
    /// Creates a stream that combines elements from a sequence of streams
    /// that yield elements of the same type, delivering an interleaved
    /// sequence of elements and completing when all streams complete.
    ///
    /// This combinator can efficiently handle arbitrary numbers of streams
    /// but has more overhead than the simpler `merge(_:_:)` variants.
    ///
    ///     var s = Stream.mergeAll([
    ///         Stream.sequence(0..<3),
    ///         Stream.sequence(3..<6),
    ///         Stream.sequence(6..<9),
    ///     ])
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 7)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 8)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == C.Element.StreamType.Output>`
    @inlinable
    public static func mergeAll<C: Sequence>(_ streams: C) -> Stream._Private.MergeAll<C.Element.StreamType> where C.Element: StreamConvertible {
        return .init(streams.lazy.map { $0.makeStream() })
    }

    /// - Returns: `some StreamProtocol<Output == S.Output>`
    @inlinable
    public static func mergeAll<S>(_ streams: S...) -> Stream._Private.MergeAll<S> {
        return .init(streams)
    }

    /// Creates a stream that combines elements from two streams that yield
    /// elements of the same type, delivering an interleaved sequence of
    /// elements and completing when both streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     var s = Stream.merge(a, b)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == A.Output>`
    @inlinable
    public static func merge<A, B>(_ a: A, _ b: B) -> Stream._Private.Merge<A, B> {
        return .init(a, b)
    }

    /// Creates a stream that combines elements from three streams that yield
    /// elements of the same type, delivering an interleaved sequence of
    /// elements and completing when all streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     let c = Stream.sequence(6..<9)
    ///     var s = Stream.merge(a, b, c)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 7)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 8)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == A.Output>`
    @inlinable
    public static func merge<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Merge3<A, B, C> {
        return .init(a, b, c)
    }

    /// Creates a stream that combines elements from four streams that yield
    /// elements of the same type, delivering an interleaved sequence of
    /// elements and completing when all streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     let c = Stream.sequence(6..<9)
    ///     let d = Stream.sequence(9..<12)
    ///     var s = Stream.merge(a, b, c, d)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == 9)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 7)
    ///     assert(s.next() == 10)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 8)
    ///     assert(s.next() == 11)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == A.Output>`
    @inlinable
    public static func merge<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> Stream._Private.Merge4<A, B, C, D> {
        return .init(a, b, c, d)
    }

    /// Creates a stream that combines elements from two streams by waiting
    /// until both streams have yielded an element and then yielding the oldest
    /// unconsumed element from each stream together as a tuple, completing
    /// when either of the streams completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     var s = Stream.zip(a, b)
    ///     assert(s.next() == (1, "A"))
    ///     assert(s.next() == (2, "B"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output)>`
    @inlinable
    public static func zip<A, B>(_ a: A, _ b: B) -> Stream._Private.Zip<A, B> {
        return .init(a, b)
    }

    /// Creates a stream that combines elements from three streams by waiting
    /// until all streams have yielded an element and then yielding the oldest
    /// unconsumed element from each stream together as a tuple, completing
    /// when any of the streams completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     var s = Stream.zip(a, b, c)
    ///     assert(s.next() == (1, "A", "X"))
    ///     assert(s.next() == (2, "B", "Y"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output, C.Output)>`
    @inlinable
    public static func zip<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Zip3<A, B, C> {
        return .init(a, b, c)
    }

    /// Combines elements from four streams by waiting until all streams have
    /// yielded an element and then yielding the oldest unconsumed element
    /// from each stream together as a tuple, completing when any stream
    /// completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     let d = Stream.sequence(3..<6)
    ///     var s = Stream.zip(a, b, c, d)
    ///     assert(s.next() == (1, "A", "X", 3))
    ///     assert(s.next() == (2, "B", "Y", 4))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output, C.Output, D.Output)>`
    @inlinable
    public static func zip<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> Stream._Private.Zip4<A, B, C, D> {
        return .init(a, b, c, d)
    }

    /// Creates a stream that combines elements from two streams and delivers
    /// pairs of elements as tuples when either stream yields an element,
    /// completing when both streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     var s = Stream.join(a, b)
    ///     assert(s.next() == (1, "A"))
    ///     assert(s.next() == (2, "B"))
    ///     assert(s.next() == (2, "C"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output)>`
    @inlinable
    public static func join<A, B>(_ a: A, _ b: B) -> Stream._Private.Join<A, B> {
        return .init(a, b)
    }

    /// Creates a stream that combines elements from three streams and
    /// delivers groups of elements as tuples when any stream yields an
    /// element, completing when all of the streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     var s = Stream.join(a, b, c)
    ///     assert(s.next() == (1, "A", "X"))
    ///     assert(s.next() == (2, "B", "Y"))
    ///     assert(s.next() == (2, "C", "Z"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output, C.Output)>`
    @inlinable
    public static func join<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Join3<A, B, C> {
        return .init(a, b, c)
    }

    /// Creates a stream that combines elements from four streams and delivers
    /// groups of elements as tuples when any stream yields an element,
    /// completing when all of the streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     let d = Stream.sequence(3..<6)
    ///     var s = Stream.join(a, b, c, d)
    ///     assert(s.next() == (1, "A", "X", 3))
    ///     assert(s.next() == (2, "B", "Y", 4))
    ///     assert(s.next() == (2, "C", "Z", 5))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (A.Output, B.Output, C.Output, D.Output)>`
    @inlinable
    public static func join<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> Stream._Private.Join4<A, B, C, D> {
        return .init(a, b, c, d)
    }
}

extension StreamProtocol {
    /// Combines elements from this stream with those from another stream that
    /// yields elements of the same type, delivering an interleaved sequence
    /// of elements and completing when both streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     var s = a.merge(b)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func merge<S>(_ other: S) -> Stream._Private.Merge<Self, S> {
        return .init(self, other)
    }

    /// Combines elements from this stream with those from two other streams
    /// that yield elements of the same type, delivering an interleaved
    /// sequence of elements and completing when all streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     let c = Stream.sequence(6..<9)
    ///     var s = a.merge(b, c)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 7)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 8)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func merge<A, B>(_ a: A, _ b: B) -> Stream._Private.Merge3<Self, A, B> {
        return .init(self, a, b)
    }

    /// Combines elements from this stream with those from three other streams
    /// that yield elements of the same type, delivering an interleaved
    /// sequence of elements and completing when all streams complete.
    ///
    ///     let a = Stream.sequence(0..<3)
    ///     let b = Stream.sequence(3..<6)
    ///     let c = Stream.sequence(6..<9)
    ///     let d = Stream.sequence(9..<12)
    ///     var s = a.merge(b, c, d)
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 6)
    ///     assert(s.next() == 9)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == 7)
    ///     assert(s.next() == 10)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 5)
    ///     assert(s.next() == 8)
    ///     assert(s.next() == 11)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func merge<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Merge4<Self, A, B, C> {
        return .init(self, a, b, c)
    }

    /// Combines elements from this stream with those from another stream by
    /// waiting until both streams have yielded an element and then yielding
    /// the oldest unconsumed element from each stream together as a tuple,
    /// completing when either stream completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     var s = a.zip(b)
    ///     assert(s.next() == (1, "A"))
    ///     assert(s.next() == (2, "B"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, S.Output)>`
    @inlinable
    public func zip<S>(_ other: S) -> Stream._Private.Zip<Self, S> {
        return .init(self, other)
    }

    /// Combines elements from this stream with those from two other streams
    /// by waiting until all three streams have yielded an element and then
    /// yielding the oldest unconsumed element from each stream together as a
    /// tuple, completing when any of the streams completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     var s = a.zip(b, c)
    ///     assert(s.next() == (1, "A", "X"))
    ///     assert(s.next() == (2, "B", "Y"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, A.Output, B.Output)>`
    @inlinable
    public func zip<A, B>(_ a: A, _ b: B) -> Stream._Private.Zip3<Self, A, B> {
        return .init(self, a, b)
    }

    /// Combines elements from this stream with those from three other streams
    /// by waiting until all four streams have yielded an element and then
    /// yielding the oldest unconsumed element from each stream together as a
    /// tuple, completing when any of the streams completes.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     let d = Stream.sequence(3..<6)
    ///     var s = a.zip(b, c, d)
    ///     assert(s.next() == (1, "A", "X", 3))
    ///     assert(s.next() == (2, "B", "Y", 4))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, A.Output, B.Output, C.Output)>`
    @inlinable
    public func zip<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Zip4<Self, A, B, C> {
        return .init(self, a, b, c)
    }

    /// Combines elements from this stream with those from another stream and
    /// delivers pairs of elements as tuples when either stream yields an
    /// element, completing when both of the streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     var s = a.join(b)
    ///     assert(s.next() == (1, "A"))
    ///     assert(s.next() == (2, "B"))
    ///     assert(s.next() == (2, "C"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, S.Output)>`
    @inlinable
    public func join<S>(_ other: S) -> Stream._Private.Join<Self, S> {
        return .init(self, other)
    }

    /// Combines elements from this stream with those from two other streams
    /// and delivers groups of elements as tuples when any stream yields an
    /// element, completing when all of the streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     var s = a.join(b, c)
    ///     assert(s.next() == (1, "A", "X"))
    ///     assert(s.next() == (2, "B", "Y"))
    ///     assert(s.next() == (2, "C", "Z"))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, A.Output, B.Output)>`
    @inlinable
    public func join<A, B>(_ a: A, _ b: B) -> Stream._Private.Join3<Self, A, B> {
        return .init(self, a, b)
    }

    /// Combines elements from this stream with those from three other streams
    /// and delivers groups of elements as tuples when any stream yields an
    /// element, completing when all of the streams complete.
    ///
    /// This is the combinator typically called `combineLatest` in other
    /// frameworks.
    ///
    ///     let a = Stream.sequence([1, 2])
    ///     let b = Stream.sequence(["A", "B", "C"])
    ///     let c = Stream.sequence(["X", "Y", "Z"])
    ///     let d = Stream.sequence(3..<6)
    ///     var s = a.join(b, c, d)
    ///     assert(s.next() == (1, "A", "X", 3))
    ///     assert(s.next() == (2, "B", "Y", 4))
    ///     assert(s.next() == (2, "C", "Z", 5))
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == (Self.Output, A.Output, B.Output, C.Output)>`
    @inlinable
    public func join<A, B, C>(_ a: A, _ b: B, _ c: C) -> Stream._Private.Join4<Self, A, B, C> {
        return .init(self, a, b, c)
    }
}

// MARK: - Adapting Stream Types -

extension StreamProtocol where Output: StreamConvertible {
    /// Flattens the stream of elements from multiple streams to appear as if
    /// they were coming from a single stream, by switching the inner stream
    /// as new ones are yielded by this stream and completing when this stream
    /// and the last inner one complete.
    ///
    ///     let a = Stream.sequence(0..<3).map {
    ///         Stream.sequence($0..<($0 + 3))
    ///     }
    ///     var s = a.switchToLatest()
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output.StreamType.Output>`
    @inlinable
    public func switchToLatest() -> Stream._Private.SwitchToLatest<Self> {
        return .init(base: self)
    }

    /// Flattens the stream of elements from multiple streams to appear as if
    /// they were coming from a single stream, by concatenating the inner
    /// streams as they are yielded by this stream and completes when this
    /// stream and the last inner one complete.
    ///
    ///     let a = Stream.sequence(0..<3).map {
    ///         Stream.sequence($0..<($0 + 3))
    ///     }
    ///     var s = a.flatten()
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 1)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == 3)
    ///     assert(s.next() == 4)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output.StreamType.Output>`
    @inlinable
    public func flatten() -> Stream._Private.Flatten<Self> {
        return .init(base: self)
    }
}

// MARK: - Creating Failable Streams -

extension StreamProtocol {
    /// Transforms the output from this stream with a provided error-throwing
    /// closure.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     var s = Stream.sequence(0..<3).tryMap { answer -> Int in
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try? s.next()!.get() == nil)
    ///     assert(try! s.next()!.get() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<T, Error>>`
    @inlinable
    public func tryMap<T>(_ catching: @escaping (Output) throws -> T) -> Stream._Private.TryMap<T, Self> {
        return .init(base: self, catching: catching)
    }

    /// Converts this stream to a failable one with the specified failure
    /// type.
    ///
    /// You typically use this combinator to match the error types of two
    /// mismatched failable streams.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     var s = Stream.sequence(0..<3).setFailureType(to: UltimateQuestionError.self)
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try! s.next()!.get() == 1)
    ///     assert(try! s.next()!.get() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<Self.Output, E>>`
    @inlinable
    public func setFailureType<E>(to _: E.Type) -> Stream._Private.SetFailureType<Output, E, Self> {
        return .init(base: self)
    }
}

// MARK: - Working with Failable Streams -

extension StreamProtocol where Output: _ResultConvertible {
    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a = Stream.sequence(0..<3).tryMap(validateAnswer)
    ///     var s = a.match(
    ///         success: String.init,
    ///         failure: String.init(describing:)
    ///     )
    ///
    ///     assert(s.next() == "0")
    ///     assert(s.next() == "wrongAnswer")
    ///     assert(s.next() == "2")
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == T>`
    @inlinable
    public func match<T>(
        success: @escaping (Output.Success) -> T,
        failure: @escaping (Output.Failure) -> T
    ) -> Stream._Private.MatchResult<T, Self> {
        return .init(base: self, success: success, failure: failure)
    }

    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     var s = Stream.sequence(0..<3).tryMap(validateAnswer).mapValue {
    ///         $0 + 1
    ///     }
    ///
    ///     assert(try! s.next()!.get() == 1)
    ///     assert(try? s.next()!.get() == nil)
    ///     assert(try! s.next()!.get() == 3)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<T, Self.Output.Failure>>`
    @inlinable
    public func mapValue<T>(_ transform: @escaping (Output.Success) -> T) -> Stream._Private.MapResult<T, Output.Failure, Self> {
        return .init(base: self, success: transform)
    }

    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     struct WrappedError: Error {
    ///         let error: Error
    ///     }
    ///
    ///     var s = Stream.sequence(0..<3).tryMap(validateAnswer).mapError {
    ///         WrappedError(error: $0)
    ///     }
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try? s.next()!.get() == nil)
    ///     assert(try! s.next()!.get() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<Self.Output.Success, E>>`
    @inlinable
    public func mapError<E>(_ transform: @escaping (Output.Failure) -> E) -> Stream._Private.MapResult<Output.Success, E, Self> {
        return .init(base: self, failure: transform)
    }
}

// MARK: -

extension StreamProtocol where Output: _ResultConvertible, Output.Success: _ResultConvertible, Output.Failure == Output.Success.Failure {
    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a = Stream.sequence(0..<3)
    ///         .tryMap(validateAnswer)
    ///         .mapValue(Result<Int, Error>.success)
    ///
    ///     var s = a.flattenResult()
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try? s.next()!.get() == nil)
    ///     assert(try! s.next()!.get() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<Self.Output.Success.Success, Self.Output.Failure>>`
    @inlinable
    public func flattenResult() -> Stream._Private.FlattenResult<Self> {
        return .init(base: self)
    }
}

// MARK: -

extension StreamProtocol where Output: _ResultConvertible, Output.Failure == Never {
    /// Changes the failure type declared by this stream.
    ///
    /// You typically use this combinator to match the error types of two
    /// mismatched result streams.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     let a = Stream.sequence(0..<3).map(Result<Int, Never>.success)
    ///     var s = a.setFailureType(to: UltimateQuestionError.self)
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try! s.next()!.get() == 1)
    ///     assert(try! s.next()!.get() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Result<Self.Output.Success, E>>`
    @inlinable
    public func setFailureType<E>(to _: E.Type) -> Stream._Private.SetFailureType<Output.Success, E, Self> {
        return .init(base: self)
    }
}

// MARK: - Handling Errors -

extension StreamProtocol where Output: _ResultConvertible {
    /// Raises a fatal error when this stream fails.
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output.Success>`
    @inlinable
    public func assertNoError(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> Stream._Private.AssertNoError<Self> {
        return .init(base: self, prefix: prefix, file: file, line: line)
    }

    /// Ensures this stream completes on the first error that occurs.
    ///
    /// Result streams in Futures do not terminate when an error occurs. This
    /// combinator allows you to selectively change that behavior on a per-
    /// stream basis so that it terminates when an error occurs.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a = Stream.sequence(0..<3).tryMap(validateAnswer)
    ///     var s = a.completeOnError()
    ///
    ///     assert(try! s.next()!.get() == 0)
    ///     assert(try? s.next()!.get() == nil)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func completeOnError() -> Stream._Private.CompleteOnError<Self> {
        return .init(base: self)
    }

    /// Replaces any errors in the stream with the provided element.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a = Stream.sequence(0..<3).tryMap(validateAnswer)
    ///     var s = a.replaceError(with: 42)
    ///
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output.Success>`
    @inlinable
    public func replaceError(with output: Output.Success) -> Stream._Private.ReplaceError<Self> {
        return .init(base: self, output: output)
    }

    /// Handles errors from this stream by replacing them with the output from
    /// another future.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         if answer == 1 {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     var s = Stream.sequence(0..<3).tryMap(validateAnswer).catchError {
    ///         _ in Stream.just(42)
    ///     }
    ///
    ///     assert(s.next() == 0)
    ///     assert(s.next() == 42)
    ///     assert(s.next() == 2)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output.Success>`
    @inlinable
    public func catchError<U>(_ errorHandler: @escaping (Output.Failure) -> U) -> Stream._Private.CatchError<U, Self> {
        return .init(base: self, errorHandler: errorHandler)
    }
}

// MARK: - Controlling Timing -

extension StreamProtocol {
    // TODO: measureInterval
    // TODO: debounce
    // TODO: delay
    // TODO: throttle
    // TODO: timeout
}

// MARK: - Encoding and Decoding -

extension StreamProtocol {
    // TODO: decode
    // TODO: encode
}

// MARK: - Debugging -

extension StreamProtocol {
    /// Raises a debugger signal when a provided closure needs to stop the
    /// process in the debugger.
    ///
    /// When any of the provided closures returns `true`, this stream raises
    /// the `SIGTRAP` signal to stop the process in the debugger.
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func breakpoint(
        ready: @escaping (Output) -> Bool = { _ in false },
        pending: @escaping () -> Bool = { false },
        complete: @escaping () -> Bool = { false }
    ) -> Stream._Private.Breakpoint<Self> {
        return .init(base: self, ready: ready, pending: pending, complete: complete)
    }

    /// Performs the specified closures when poll events occur.
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func handleEvents(
        ready: @escaping (Output) -> Void = { _ in },
        pending: @escaping () -> Void = {},
        complete: @escaping () -> Void = {}
    ) -> Stream._Private.HandleEvents<Self> {
        return .init(base: self, ready: ready, pending: pending, complete: complete)
    }

    /// Prints log messages for all poll events.
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func print(_ prefix: String = "", to stream: TextOutputStream? = nil) -> Stream._Private.Print<Self> {
        return .init(base: self, prefix: prefix, to: stream)
    }
}

// MARK: -

extension StreamProtocol where Output: _ResultConvertible {
    /// Raises a debugger signal upon receiving a failure.
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func breakpointOnError() -> Stream._Private.Breakpoint<Self> {
        return .init(
            base: self,
            ready: { $0._makeResult()._isFailure },
            pending: { false },
            complete: { false }
        )
    }
}

// MARK: - Private -

/// :nodoc:
extension Stream {
    public enum _Private {}
}
