//
//  Promise.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// An one-shot slot that can be used to communicate a value between tasks.
///
/// `Promise` is safe to use between any number of tasks that are racing to
/// provide the value and a *single* task that is polling for it.
///
/// `Promise` is only able to communicate a single value. If you need to
/// efficiently communicate a sequence of asynchronously produced values, see
/// `Channel.Unbuffered`.
public final class Promise<Output>: FutureProtocol {
    @usableFromInline
    struct State: AtomicBitset {
        @usableFromInline typealias RawValue = AtomicUInt.RawValue
        @usableFromInline let rawValue: RawValue

        @inlinable
        init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        @inlinable static var pending: State { 0 }
        @inlinable static var polling: State { 0b001 }
        @inlinable static var resolving: State { 0b010 }
        @inlinable static var resolved: State { 0b100 }
    }

    @usableFromInline var _state: State.RawValue = 0
    @usableFromInline var _waker: WakerProtocol?

    // swiftlint:disable:next implicitly_unwrapped_optional
    @usableFromInline var _output: Output!

    @inlinable
    public init() {
        State.initialize(&_state, to: .pending)
    }

    @inlinable
    public func poll(_ context: inout Context) -> Poll<Output> {
        switch State.compareExchange(&_state, .pending, .polling) {
        case .pending:
            // Lock acquired; save the waker
            _waker = context.waker

            // Release the lock but check whether in the meantime the promise
            // was, or is just about to be, resolved.
            switch State.compareExchange(&_state, .polling, .pending) {
            case .polling:
                return .pending
            case let actual:
                if actual.contains(.resolved) {
                    return .ready(_output)
                }
                if actual.contains(.resolving) {
                    // We're just about to get the output. Yield to the
                    // executor in order to repoll the soonest possible.
                    return context.yield()
                }
                assert(actual == .pending)
                fatalError("unreachable")
            }

        case .resolving:
            return context.yield()

        case let actual:
            if actual.contains(.resolved) {
                // swiftlint:disable:next force_unwrapping
                return .ready(_output.move()!)
            }
            assert(actual == .pending)
            fatalError("concurrent attempt to poll Promise")
        }
    }

    @inlinable
    public func resolve(_ output: Output) {
        let curr = State.fetchOr(&_state, .resolving)
        if curr.contains(.resolving) {
            // Either the promise is already resolved, or some other
            // thread won the race and will soon resolve it.
            return
        }
        // Lock acquired; store the value
        _output = output

        // Publish that the promise is now resolved and signal the
        // waker if needed.
        if !State.exchange(&_state, .resolved).contains(.polling) {
            _waker?.signal()
        }
    }
}

extension Promise {
    /// :nodoc:
    public enum Resolve<F: FutureProtocol>: FutureProtocol where F.Output == Output {
        public struct _State {
            @usableFromInline let promise: WeakReference<Promise>
            @usableFromInline var future: F

            @inlinable
            init(promise: Promise, future: F) {
                self.promise = .init(promise)
                self.future = future
            }
        }

        case pending(_State)
        case done

        @inlinable
        public init(promise: Promise, future: F) {
            self = .pending(.init(promise: promise, future: future))
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Void> {
            switch self {
            case .pending(var state):
                guard let promise = state.promise.value else {
                    self = .done
                    return .ready(())
                }
                return withExtendedLifetime(promise) {
                    switch state.future.poll(&context) {
                    case .ready(let output):
                        promise.resolve(output)
                        self = .done
                        return .ready(())
                    case .pending:
                        self = .pending(state)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }

    @inlinable
    public func resolve<F: FutureProtocol>(when future: F) -> Resolve<F> {
        return .init(promise: self, future: future)
    }
}
