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
    enum _State: AtomicInt.RawValue {
        case idle
        case polling
        case resolving
        case resolved
    }

    @usableFromInline var _state: _State.RawValue = 0
    @usableFromInline var _output: Output?
    @usableFromInline var _waker: WakerProtocol?

    @inlinable
    public init() {
        _State.initialize(&_state, to: .idle)
    }

    @inlinable
    public func poll(_ context: inout Context) -> Poll<Output> {
        var backoff = Backoff()
        while true {
            switch _State.compareExchangeWeak(&_state, .idle, .polling) {
            case .idle:
                _waker = context.waker
                let previous = _State.exchange(&_state, .idle)
                assert(previous == .polling)
                return .pending

            case .resolved:
                // swiftlint:disable:next force_unwrapping
                return .ready(_output!)

            case .resolving:
                if backoff.spin() {
                    return context.yield()
                }

            case .polling:
                fatalError("concurrent attempt to poll Promise")
            }
        }
    }
}

extension Promise {
    /// :nodoc:
    public enum Resolve<F: FutureProtocol>: FutureProtocol where F.Output == Output {
        case pending(Promise, F)
        case done

        @inlinable
        public init(promise: Promise, future: F) {
            self = .pending(promise, future)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Void> {
            switch self {
            case .pending(let promise, var future):
                switch future.poll(&context) {
                case .ready(let output):
                    self = .done
                    promise.resolve(output)
                    return .ready
                case .pending:
                    self = .pending(promise, future)
                    return .pending
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

    @inlinable
    public func resolve(_ value: Output) {
        var backoff = Backoff()
        while true {
            switch _State.compareExchangeWeak(&_state, .idle, .resolving) {
            case .idle:
                let waker = _waker.take()
                _output = value
                let previous = _State.exchange(&_state, .resolved)
                assert(previous == .resolving)
                waker?.signal()
                return

            case .resolved, .resolving:
                return

            case .polling:
                // FIXME: return if we exhausted our budget
                _ = backoff.yield()
            }
        }
    }
}

extension Promise where Output == Void {
    @inlinable
    public func resolve() {
        resolve(())
    }
}
