//
//  Future.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol that defines a container for the result of an asynchronous
/// operation, such as an HTTP request, a timeout, a disk I/O operation, etc.
///
/// Futures can be *pending*, meaning that the result of the operation is not
/// available yet, or *completed*, meaning that the result is ready. Futures
/// can be combined into larger operations with *combinators*, such as `map(_:)`,
/// `flatMap(_:)`, etc.
///
/// Futures communicate a single value of type `Output`. Semantically, futures
/// capture only the notion of *completion*; that is, there is no explicit
/// distinction between a successful or a failed operation. Operations that
/// must communicate success or failure, must do so by encoding that information
/// in the output type, typically using `Swift.Result`. Futures comes with a
/// number of convenience types and combinators for working with `Swift.Result`
/// (see `ResultFuture`).
///
/// You typically create futures using the static convenience methods on the
/// `Future` namespace. You can also create custom futures by adopting this
/// protocol in your types.
///
/// Creating futures is *always* an asynchronous operation. The builtin types
/// guarantee that the operation the future wraps will only be started after
/// the future is submitted to an executor (see `ExecutorProtocol`). Custom
/// future implementations must also provide the same guarantee.
///
/// Memory and Concurrency Management
/// ---------------------------------
///
/// When a future is submitted to an executor, ownership of the future and its
/// resources is transferred into the executor. You can only affect its fate
/// indirectly from that point on (see `Task`).
///
/// When a future completes, it is effectively dropped and its resources are
/// released on the same execution context (eg. a thread or a Dispatch queue)
/// the future was started and polled in.
///
/// This makes both memory and concurrency management predictable and extremely
/// easy to reason about; a future's lifetime is wholly contained within the
/// executor it was submitted on.
///
/// Cancellation
/// ------------
///
/// Futures support cancellation implicitly. As discussed above, for a future
/// to make progress, it must be polled by an executor. By simply not polling
/// the future and instead dropping it effectively cancels the underlying
/// operation. To explicitly cancel a submitted future, use `Task`.
///
/// If the operation is allocating resources that must be released manually,
/// you can provide a "cancellation token" at creation which will automatically
/// invoke a given closure upon deallocation, be it due to completion or
/// cancellation (see `Deferred`).
public protocol FutureProtocol: FutureConvertible where FutureType == Self {
    associatedtype Output
    mutating func poll(_ context: inout Context) -> Poll<Output>
}

public protocol FutureConvertible {
    associatedtype FutureType: FutureProtocol
    nonmutating func makeFuture() -> FutureType
}

extension FutureConvertible where Self: FutureProtocol {
    /// .
    ///
    ///     var f = Future.ready(42).makeFuture()
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @_transparent
    public func makeFuture() -> Self {
        return self
    }
}

/// A namespace for types and convenience methods related to futures.
///
/// For details on futures, see `FutureProtocol`.
public enum Future {}

// MARK: - Creating Futures -

/// A type-erasing future.
///
/// Use `AnyFuture` to wrap a future whose type has details you don’t want to
/// expose. This is typically the case when returning futures from a function
/// or storing futures in properties.
///
/// You can also use `AnyFuture` to create a custom future by providing a
/// closure for the `poll` method, rather than implementing `FutureProtocol`
/// directly on a custom type.
public struct AnyFuture<Output>: FutureProtocol {
    public typealias PollFn = (inout Context) -> Poll<Output>

    @usableFromInline let _pollFn: PollFn

    /// Creates a type-erasing future implemented by the provided closure.
    @inlinable
    public init(_ pollFn: @escaping PollFn) {
        _pollFn = pollFn
    }

    /// Creates a type-erasing future to wrap the provided future.
    ///
    /// This initializer performs a heap allocation unless the wrapped future
    /// is already type-erased.
    @inlinable
    public init<F: FutureProtocol>(_ future: F) where F.Output == Output {
        if let f = future as? AnyFuture {
            _pollFn = f._pollFn
        } else {
            var f = future
            _pollFn = {
                f.poll(&$0)
            }
        }
    }

    @inlinable
    public func poll(_ context: inout Context) -> Poll<Output> {
        return _pollFn(&context)
    }
}

public struct Deferred<Output>: FutureProtocol {
    public typealias Operation = (Promise<Output>) -> AnyCancellable

    @usableFromInline
    enum _State {
        case pending(Promise<Output>, Operation)
        case waiting(Promise<Output>, AnyCancellable)
        case done
    }

    @usableFromInline var _state: _State

    @inlinable
    public init(_ body: @escaping Operation) {
        _state = .pending(.init(), body)
    }

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch _state {
            case .pending(let promise, let resolver):
                let canceller = resolver(promise)
                _state = .waiting(promise, canceller)
                continue

            case .waiting(let promise, let canceller):
                switch promise.poll(&context) {
                case .ready(let output):
                    _state = .done
                    return .ready(output)
                case .pending:
                    _state = .waiting(promise, canceller)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}

extension Future {
    /// Creates a future that never completes.
    ///
    ///     var f = Future.never(outputType: Void.self)
    ///     f.wait() // will block forever
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public static func never<T>(outputType _: T.Type = T.self) -> Future._Private.Never<T> {
        return .init()
    }

    /// Creates a future that completes immediately.
    ///
    ///     var f = Future.ready()
    ///     assert(f.wait() == ())
    ///
    /// - Returns: `some FutureProtocol<Output == Void>`
    @inlinable
    public static func ready() -> Future._Private.Ready<Void> {
        return .init()
    }

    /// Creates a future that completes immediately with the given value.
    ///
    ///     var f = Future.ready(42)
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public static func ready<T>(_ output: T) -> Future._Private.Ready<T> {
        return .init(output: output)
    }

    /// Creates a future that lazily invokes the given closure, awaits the
    /// returned future and completes with that future's value.
    ///
    ///     var f = Future.lazy {
    ///         Future.ready(42)
    ///     }
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == U.FutureType.Output>`
    @inlinable
    public static func `lazy`<U>(_ body: @escaping () -> U) -> Future._Private.Lazy<U> {
        return .init(body)
    }
}

// MARK: - Instance Methods -

extension FutureProtocol {
    /// .
    ///
    ///     var s = Future.ready(42).makeStream()
    ///     assert(s.next() == 42)
    ///     assert(s.next() == nil)
    ///
    /// - Returns: `some StreamProtocol<Output == Self.Output>`
    @inlinable
    public func makeStream() -> Future._Private.Stream<Self> {
        return .init(base: self)
    }

    /// .
    ///
    ///     let f1 = Future.ready(4).makeReference()
    ///     let f2 = Future.ready(2).makeReference()
    ///     var f = Future.join(f1, f2)
    ///     assert(f.wait() == (4, 2))
    ///     // assert(f1.wait() == 4) // traps
    ///     // assert(f2.wait() == 2) // traps
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func makeReference() -> Future._Private.Reference<Self> {
        return .init(base: self)
    }

    /// Synchronously polls this future on the current thread's executor until
    /// it completes.
    ///
    ///     var f = Future.ready(42)
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `Self.Output`
    @inlinable
    public mutating func wait() -> Output {
        return ThreadExecutor.current.run(until: &self)
    }

    // TODO: assign
    // TODO: sink

    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func abort<U>(when f: U) -> Future._Private.Abort<U, Self> {
        return .init(base: self, signal: { f })
    }

    /// - Returns: `some FutureProtocol<Output == Self.Output?>`
    @inlinable
    public func abort<U>(when f: @escaping () -> U) -> Future._Private.Abort<U, Self> {
        return .init(base: self, signal: f)
    }

    /// Ensures this future is polled on the given executor.
    ///
    /// The returned future retains the executor for its whole lifetime.
    ///
    ///     var f = Future.ready(42)
    ///         .poll(on: QueueExecutor.global)
    ///         .assertNoError()
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Self.Output, E.Failure>>`
    @inlinable
    public func poll<E: ExecutorProtocol>(on executor: E) -> Future._Private.PollOn<E, Self> {
        return .init(base: self, executor: executor)
    }
}

// MARK: - Vending Futures -

extension FutureProtocol {
    /// .
    ///
    ///     var f = Future.ready(42).eraseToAnyFuture()
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `AnyFuture<Self.Output>`
    @inlinable
    public func eraseToAnyFuture() -> AnyFuture<Output> {
        return .init(self)
    }
}

extension FutureProtocol {
    // TODO: multicast()
    // TODO: eraseToAnyMulticastFuture()
}

extension FutureProtocol {
    // TODO: share()
    // TODO: eraseToAnySharedFuture()
}

// MARK: - Transforming Output -

extension FutureProtocol {
    /// Transforms the output from this future with a provided closure.
    ///
    ///     var f = Future.ready(4).map {
    ///         String($0) + "2"
    ///     }
    ///     assert(f.wait() == "42")
    ///
    /// For a variation of this combinator that accepts an error-throwing
    /// closure see `tryMap(_:)`.
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func map<T>(_ transform: @escaping (Output) -> T) -> Future._Private.Map<T, Self> {
        return .init(base: self, transform: transform)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a: Int
    ///     }
    ///     let data = Data(a: 42)
    ///     var f = Future.ready(data).map(\.a)
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func map<T>(_ keyPath: KeyPath<Output, T>) -> Future._Private.MapKeyPath<T, Self> {
        return .init(base: self, keyPath: keyPath)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a, b: Int
    ///     }
    ///     let data = Data(a: 4, b: 2)
    ///     var f = Future.ready(data).map(\.a, \.b)
    ///     assert(f.wait() == (4, 2))
    ///
    /// - Returns: `some FutureProtocol<Output == (T0, T1)>`
    @inlinable
    public func map<T0, T1>(_ keyPath0: KeyPath<Output, T0>, _ keyPath1: KeyPath<Output, T1>) -> Future._Private.MapKeyPath2<T0, T1, Self> {
        return .init(base: self, keyPath0: keyPath0, keyPath1: keyPath1)
    }

    /// .
    ///
    ///     struct Data {
    ///         let a, b, c: Int
    ///     }
    ///     let data = Data(a: 4, b: 2, c: 5)
    ///     var f = Future.ready(data).map(\.a, \.b, \.c)
    ///     assert(f.wait() == (4, 2, 5))
    ///
    /// - Returns: `some FutureProtocol<Output == (T0, T1, T2)>`
    @inlinable
    public func map<T0, T1, T2>(_ keyPath0: KeyPath<Output, T0>, _ keyPath1: KeyPath<Output, T1>, _ keyPath2: KeyPath<Output, T2>) -> Future._Private.MapKeyPath3<T0, T1, T2, Self> {
        return .init(base: self, keyPath0: keyPath0, keyPath1: keyPath1, keyPath2: keyPath2)
    }

    /// .
    ///
    ///     var f = Future.ready(4).flatMap {
    ///         Future.ready(String($0) + "2")
    ///     }
    ///     assert(f.wait() == "42")
    ///
    /// - Returns: `some FutureProtocol<Output == U.FutureType.Output>`
    @inlinable
    public func flatMap<U>(_ transform: @escaping (Output) -> U) -> Future._Private.FlatMap<U, Self> {
        return .init(base: self, transform: transform)
    }

    /// .
    ///
    ///     var f = Future.ready(14).then(on: QueueExecutor.global) {
    ///         Future.ready($0 * 3)
    ///     }
    ///     assert(f.wait() == Result.success(42))
    ///
    /// - Returns: `some FutureProtocol<Output == Result<U.FutureType.Output, E.Failure>>`
    @inlinable
    public func then<E, U>(on executor: E, _ execute: @escaping (Output) -> U) -> Future._Private.Then<E, U, Self> {
        return .init(base: self, executor: executor, continuation: execute)
    }

    /// Calls the given closure on the output of this future.
    ///
    ///     var f = Future.ready(42).peek {
    ///         print($0)
    ///     }
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func peek(_ body: @escaping (Output) -> Void) -> Future._Private.Peek<Self> {
        return .init(base: self, body: body)
    }

    /// Replaces the output from this future with a provided value, if it is
    /// nil.
    ///
    ///     var f1 = Future.ready(Int?.some(5)).replaceNil(with: 42)
    ///     assert(f1.wait() == 5)
    ///
    ///     var f2 = Future.ready(Int?.none).replaceNil(with: 42)
    ///     assert(f2.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func replaceNil<T>(with output: T) -> Future._Private.Map<T, Self> where Output == T? {
        return .init(base: self) { $0 ?? output }
    }

    /// Replaces the output from this future with a provided value.
    ///
    ///     var f = Future.ready(5).replaceOutput(with: 42)
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func replaceOutput<T>(with output: T) -> Future._Private.ReplaceOutput<T, Self> {
        return .init(base: self, output: output)
    }

    /// Ignores the output from this future.
    ///
    ///     var f = Future.ready(42).ignoreOutput()
    ///     assert(f.wait() == ())
    ///
    /// - Returns: `some FutureProtocol<Output == Void>`
    @inlinable
    public func ignoreOutput() -> Future._Private.IgnoreOutput<Self> {
        return .init(base: self)
    }

    /// .
    ///
    ///     var f1 = Future.ready(Int?.some(42)).match(
    ///         some: String.init,
    ///         none: { "NaN" }
    ///     )
    ///     assert(f1.wait() == "42")
    ///
    ///     var f2 = Future.ready(Int?.none).match(
    ///         some: String.init,
    ///         none: { "NaN" }
    ///     )
    ///     assert(f2.wait() == "NaN")
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func match<T, Wrapped>(
        some: @escaping (Wrapped) -> T,
        none: @escaping () -> T
    ) -> Future._Private.MatchOptional<T, Wrapped, Self> where Output == Wrapped? {
        return .init(base: self, some: some, none: none)
    }

    /// .
    ///
    ///     func transform(_ value: Int) -> Either<Int, Float> {
    ///         if value == 42 {
    ///             return .left(value)
    ///         } else {
    ///             return .right(.init(value))
    ///         }
    ///     }
    ///
    ///     var f1 = Future.ready(42).map(transform).match(
    ///         left: String.init,
    ///         right: String.init(describing:)
    ///     )
    ///     assert(f1.wait() == "42")
    ///
    ///     var f2 = Future.ready(5).map(transform).match(
    ///         left: String.init,
    ///         right: String.init(describing:)
    ///     )
    ///     assert(f2.wait() == "5.0")
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func match<T, Left, Right>(
        left: @escaping (Left) -> T,
        right: @escaping (Right) -> T
    ) -> Future._Private.MatchEither<T, Left, Right, Self> {
        return .init(base: self, left: left, right: right)
    }
}

// MARK: - Combining Output from Multiple Futures -

extension Future {
    /// Creates a future that collects the output from a sequence of futures
    /// that output elements of the same type and completes with an array of
    /// the elements when all futures complete.
    ///
    /// This combinator can efficiently handle arbitrary numbers of futures
    /// but has more overhead than the simpler `join(_:_:)` variants.
    ///
    ///     var f = Future.joinAll([
    ///         Future.ready(1),
    ///         Future.ready(2),
    ///         Future.ready(3),
    ///     ])
    ///     assert(f.wait() == [1, 2, 3])
    ///
    /// - Returns: `some FutureProtocol<Output == [C.Element.FutureType.Output]>`
    @inlinable
    public static func joinAll<C>(_ futures: C) -> Future._Private.JoinAll<C.Element.FutureType>
        where C: Sequence, C.Element: FutureConvertible {
        return .init(futures.lazy.map { $0.makeFuture() })
    }

    /// - Returns: `some FutureProtocol<Output == [F.Output]>`
    @inlinable
    public static func joinAll<F>(_ futures: F...) -> Future._Private.JoinAll<F> {
        return .init(futures)
    }

    /// Creates a future that combines the output from two futures by waiting
    /// until both futures complete and then completing with the output from
    /// each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     var f = Future.join(a, b)
    ///     assert(f.wait() == (1, "A"))
    ///
    /// - Returns: `some FutureProtocol<Output == (A.Output, B.Output)>`
    @inlinable
    public static func join<A, B>(_ a: A, _ b: B) -> Future._Private.Join<A, B> {
        return .init(a, b)
    }

    /// Creates a future that combines the output from three futures by waiting
    /// until all futures complete and then completing with the output from
    /// each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     let c = Future.ready("X")
    ///     var f = Future.join(a, b, c)
    ///     assert(f.wait() == (1, "A", "X"))
    ///
    /// - Returns: `some FutureProtocol<Output == (A.Output, B.Output, C.Output)>`
    @inlinable
    public static func join<A, B, C>(_ a: A, _ b: B, _ c: C) -> Future._Private.Join3<A, B, C> {
        return .init(a, b, c)
    }

    /// Creates a future that combines the output from four futures by waiting
    /// until all futures complete and then completing with the output from
    /// each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     let c = Future.ready("X")
    ///     let d = Future.ready(5)
    ///     var f = Future.join(a, b, c, d)
    ///     assert(f.wait() == (1, "A", "X", 5))
    ///
    /// - Returns: `some FutureProtocol<Output == (A.Output, B.Output, C.Output, D.Output)>`
    @inlinable
    public static func join<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D) -> Future._Private.Join4<A, B, C, D> {
        return .init(a, b, c, d)
    }

    /// Creates a future that waits until any of the given sequence of futures
    /// that output elements of the same type completes, and completes with the
    /// output from that future.
    ///
    /// This combinator can efficiently handle arbitrary numbers of futures
    /// but has more overhead than the simpler `select(_:_:)` variant.
    ///
    ///     var f = Future.selectAny([
    ///         Future.ready(1),
    ///         Future.ready(2),
    ///         Future.ready(3),
    ///     ])
    ///     assert(f.wait() == 1)
    ///
    /// - Returns: `some FutureProtocol<Output == C.Element.FutureType.Output>`
    @inlinable
    public static func selectAny<C>(_ futures: C) -> Future._Private.SelectAny<C.Element.FutureType>
        where C: Sequence, C.Element: FutureConvertible {
        return .init(futures.lazy.map { $0.makeFuture() })
    }

    /// - Returns: `some FutureProtocol<Output == F.Output>`
    @inlinable
    public static func selectAny<F>(_ futures: F...) -> Future._Private.SelectAny<F> {
        return .init(futures)
    }

    /// Creates a future that waits until either of the given futures complete,
    /// and completes with the output from that future.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     var f = Future.select(a, b)
    ///     assert(f.wait() == .left(1))
    ///
    /// - Returns: `some FutureProtocol<Output == Either<A.Output, B.Output>>`
    @inlinable
    public static func select<A, B>(_ a: A, _ b: B) -> Future._Private.Select<A, B> {
        return .init(a, b)
    }
}

extension FutureProtocol {
    /// Combines the output from this future with that from another future by
    /// waiting until both futures complete and then completing with the output
    /// from each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     var f = a.join(b)
    ///     assert(f.wait() == (1, "A"))
    ///
    /// - Returns: `some FutureProtocol<Output == (Self.Output, S.Output)>`
    @inlinable
    public func join<F>(_ other: F) -> Future._Private.Join<Self, F> {
        return .init(self, other)
    }

    /// Combines the output from this future with that from two other futures
    /// by waiting until all futures complete and then completing with the
    /// output from each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     let c = Future.ready("X")
    ///     var f = a.join(b, c)
    ///     assert(f.wait() == (1, "A", "X"))
    ///
    /// - Returns: `some FutureProtocol<Output == (Self.Output, B.Output, C.Output)>`
    @inlinable
    public func join<B, C>(_ b: B, _ c: C) -> Future._Private.Join3<Self, B, C> {
        return .init(self, b, c)
    }

    /// Combines the output from this future with that from three other futures
    /// by waiting until all futures complete and then completing with the
    /// output from each future together as a tuple.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     let c = Future.ready("X")
    ///     let d = Future.ready(5)
    ///     var f = a.join(b, c, d)
    ///     assert(f.wait() == (1, "A", "X", 5))
    ///
    /// - Returns: `some FutureProtocol<Output == (Self.Output, B.Output, C.Output, D.Output)>`
    @inlinable
    public func join<B, C, D>(_ b: B, _ c: C, _ d: D) -> Future._Private.Join4<Self, B, C, D> {
        return .init(self, b, c, d)
    }

    /// Waits until either this future or the given one complete, and completes
    /// with the output from that future.
    ///
    ///     let a = Future.ready(1)
    ///     let b = Future.ready("A")
    ///     var f = a.select(b)
    ///     assert(f.wait() == .left(1))
    ///
    /// - Returns: `some FutureProtocol<Output == Either<Self.Output, B.Output>>`
    @inlinable
    public func select<B>(_ other: B) -> Future._Private.Select<Self, B> {
        return .init(self, other)
    }
}

// MARK: - Adapting Future Types -

extension FutureProtocol where Output: FutureConvertible {
    /// Flattens the output from this future by waiting for the output of the
    /// future produced by this future.
    ///
    ///     let a = Future.ready(4).map {
    ///         Future.ready(String($0) + "2")
    ///     }
    ///     var f = a.flatten()
    ///     assert(f.wait() == "42")
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output.FutureType.Output>`
    @inlinable
    public func flatten() -> Future._Private.Flatten<Self> {
        return .init(base: self)
    }
}

// MARK: - Creating Failable Futures -

extension Future {
    /// Creates a future that lazily invokes the given error-throwing closure,
    /// awaits the returned future and completes with that future's output.
    ///
    ///     var f = Future.tryLazy {
    ///         Future.ready(42)
    ///     }
    ///     assert(try? f.wait().get() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<U.FutureType.Output, Error>>`
    @inlinable
    public static func tryLazy<U>(_ body: @escaping () throws -> U) -> Future._Private.TryLazy<U> {
        return .init(body)
    }

    // complete when either completes with an error
    // TODO: tryJoin<A, B(_ a: A, _ b: B)
    // TODO: tryJoin<A, B, C>(_ a: A, _ b: B, _ c: C)
    // TODO: tryJoin<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D)
}

extension FutureProtocol {
    /// Transforms the output from this future with a provided error-throwing
    /// closure.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     var f1 = Future.ready(42).tryMap(validateAnswer)
    ///     assert(try! f1.wait().get() == 42)
    ///
    ///     var f2 = Future.ready(5).tryMap(validateAnswer)
    ///     assert(try? f2.wait().get() == nil)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<T, Error>>`
    @inlinable
    public func tryMap<T>(_ catching: @escaping (Output) throws -> T) -> Future._Private.TryMap<T, Self> {
        return .init(base: self, catching: catching)
    }

    // complete when either completes with an error
    // TODO: tryJoin<T>(_ other: T)
    // TODO: tryJoin<B, C>(_ b: B, _ c: C)
    // TODO: tryJoin<B, C, D>(_ b: B, _ c: C, _ d: D)

    /// Converts this future to a failable one with the specified failure
    /// type.
    ///
    /// You typically use this combinator to match the error types of two
    /// mismatched failable futures.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     var f = Future.ready(42).setFailureType(to: UltimateQuestionError.self)
    ///     assert(try! f.wait().get() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Self.Output, Failure>>`
    @inlinable
    public func setFailureType<Failure>(to _: Failure.Type) -> Future._Private.SetFailureType<Output, Failure, Self> {
        return .init(base: self)
    }
}

// MARK: - Working with Failable Futures -

extension FutureProtocol {
    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a1 = Future.ready(5).tryMap(validateAnswer)
    ///     var f1 = a1.match(
    ///         success: String.init,
    ///         failure: String.init(describing:)
    ///     )
    ///     assert(f1.wait() == "wrongAnswer")
    ///
    ///     let a2 = Future.ready(42).tryMap(validateAnswer)
    ///     var f2 = a2.match(
    ///         success: String.init,
    ///         failure: String.init(describing:)
    ///     )
    ///     assert(f2.wait() == "42")
    ///
    /// - Returns: `some FutureProtocol<Output == T>`
    @inlinable
    public func match<T, Success, Failure>(
        success: @escaping (Success) -> T,
        failure: @escaping (Failure) -> T
    ) -> Future._Private.MatchResult<T, Success, Failure, Self> {
        return .init(base: self, success: success, failure: failure)
    }

    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     var f1 = Future.ready(5).tryMap(validateAnswer).mapValue {
    ///         $0 + 1
    ///     }
    ///     assert(try? f1.wait().get() == nil)
    ///
    ///     var f2 = Future.ready(42).tryMap(validateAnswer).mapValue {
    ///         $0 + 1
    ///     }
    ///     assert(try? f2.wait().get() == 43)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<NewSuccess, Self.Output.Failure>>`
    @inlinable
    public func mapValue<NewSuccess, Success, Failure>(_ transform: @escaping (Success) -> NewSuccess) -> Future._Private.MapValue<NewSuccess, Success, Failure, Self> {
        return .init(base: self, success: transform)
    }

    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     struct WrappedError: Error {
    ///         let error: Error
    ///     }
    ///
    ///     var f1 = Future.ready(5).tryMap(validateAnswer).mapError {
    ///         WrappedError(error: $0)
    ///     }
    ///     assert(try? f1.wait().get() == nil)
    ///
    ///     var f2 = Future.ready(42).tryMap(validateAnswer).mapError {
    ///         WrappedError(error: $0)
    ///     }
    ///     assert(try? f2.wait().get() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Self.Output.Success, NewFailure>>`
    @inlinable
    public func mapError<NewFailure, Success, Failure>(_ transform: @escaping (Failure) -> NewFailure) -> Future._Private.MapError<NewFailure, Success, Failure, Self> {
        return .init(base: self, failure: transform)
    }

    /// .
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a1 = Future.ready(5)
    ///         .tryMap(validateAnswer)
    ///         .mapValue(Result<Int, Error>.success)
    ///     var f1 = a1.flattenResult()
    ///     assert(try? f1.wait().get() == nil)
    ///
    ///     let a2 = Future.ready(42)
    ///         .tryMap(validateAnswer)
    ///         .mapValue(Result<Int, Error>.success)
    ///     var f2 = a2.flattenResult()
    ///     assert(try? f2.wait().get() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Self.Output.Success.Success, Self.Output.Failure>>`
    @inlinable
    public func flattenResult<Success, Failure>() -> Future._Private.FlattenResult<Success, Failure, Self> {
        return .init(base: self)
    }

    /// Changes the failure type declared by this future.
    ///
    /// You typically use this combinator to match the error types of two
    /// mismatched result futures.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     let a = Future.ready(42).map(Result<Int, Never>.success)
    ///     var f = a.setFailureType(to: UltimateQuestionError.self)
    ///
    ///     assert(try! f.wait().get() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Result<Self.Output.Success, NewFailure>>`
    @inlinable
    public func setFailureType<Success, NewFailure>(to _: NewFailure.Type) -> Future._Private.SetFailureType<Success, NewFailure, Self> where Output == Result<Success, Never> {
        return .init(base: self)
    }
}

// MARK: - Handling Errors -

extension FutureProtocol {
    /// Raises a fatal error when this future fails.
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output.Success>`
    @inlinable
    public func assertNoError<Success, Failure>(_ prefix: String = "", file: StaticString = #file, line: UInt = #line) -> Future._Private.AssertNoError<Success, Failure, Self> {
        return .init(base: self, prefix: prefix, file: file, line: line)
    }

    /// Replaces failure with the provided element.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     let a = Future.ready(5).tryMap(validateAnswer)
    ///     var f = a.replaceError(with: 42)
    ///
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output.Success>`
    @inlinable
    public func replaceError<Success, Failure>(with output: Success) -> Future._Private.ReplaceError<Success, Failure, Self> {
        return .init(base: self, output: output)
    }

    /// Handles errors from this future by replacing it with another future
    /// on failure.
    ///
    ///     enum UltimateQuestionError: Error {
    ///         case wrongAnswer
    ///     }
    ///
    ///     func validateAnswer(_ answer: Int) throws -> Int {
    ///         guard answer == 42 else {
    ///             throw UltimateQuestionError.wrongAnswer
    ///         }
    ///         return answer
    ///     }
    ///
    ///     var f = Future.ready(5).tryMap(validateAnswer).catchError {
    ///         _ in Future.ready(42)
    ///     }
    ///
    ///     assert(f.wait() == 42)
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output.Success>`
    @inlinable
    public func catchError<U, Failure>(_ errorHandler: @escaping (Failure) -> U) -> Future._Private.CatchError<U, Failure, Self> {
        return .init(base: self, errorHandler: errorHandler)
    }
}

// MARK: - Controlling Timing -

extension FutureProtocol {
    // TODO: delay
    // TODO: timeout
}

// MARK: - Encoding and Decoding -

extension FutureProtocol {
    // TODO: decode
    // TODO: encode
}

// MARK: - Debugging -

extension FutureProtocol {
    /// Raises a debugger signal when a provided closure needs to stop the
    /// process in the debugger.
    ///
    /// When any of the provided closures returns `true`, this future raises
    /// the `SIGTRAP` signal to stop the process in the debugger.
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func breakpoint(
        ready: @escaping (Output) -> Bool = { _ in false },
        pending: @escaping () -> Bool = { false }
    ) -> Future._Private.Breakpoint<Self> {
        return .init(base: self, ready: ready, pending: pending)
    }

    /// Raises a debugger signal upon receiving a failure.
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func breakpointOnError<Success, Failure>() -> Future._Private.Breakpoint<Self> where Output == Result<Success, Failure> {
        return .init(base: self)
    }

    /// Performs the specified closures when poll events occur.
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func handleEvents(
        ready: @escaping (Output) -> Void = { _ in },
        pending: @escaping () -> Void = {}
    ) -> Future._Private.HandleEvents<Self> {
        return .init(base: self, ready: ready, pending: pending)
    }

    /// Prints log messages for all poll events.
    ///
    /// - Returns: `some FutureProtocol<Output == Self.Output>`
    @inlinable
    public func print(_ prefix: String = "", to stream: TextOutputStream? = nil) -> Future._Private.Print<Self> {
        return .init(base: self, prefix: prefix, to: stream)
    }
}

// MARK: - Private -

/// :nodoc:
extension Future {
    public enum _Private {}
}
