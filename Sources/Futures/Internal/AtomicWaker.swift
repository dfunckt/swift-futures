//
//  AtomicWaker.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

// set to `false` to replace _AtomicWaker with a simple
// thread-safe waker that is useful for debugging.
#if true

/// A primitive for synchronizing attempts to wake a task.
@usableFromInline
final class _AtomicWaker: WakerProtocol {
    private struct State: OptionSet {
        var rawValue: AtomicUInt.RawValue

        static let waiting: State = []
        static let registering = State(rawValue: 1)
        static let notifying = State(rawValue: 2)
        static let notified = State(rawValue: ~notifying.rawValue)
    }

    private var _state: State.RawValue = 0
    private var _waker: WakerProtocol?

    @usableFromInline
    init() {
        State.initialize(&_state, to: .waiting)
    }

    /// Register a waker to be notified on calls to `signal()`.
    /// Returns `true` if the waker was immediately signalled instead.
    /// This method is not thread-safe.
    @usableFromInline
    func register(_ waker: WakerProtocol) {
        if let w = _exchange(waker) {
            w.signal()
        }
    }

    /// Exchange the waker to be notified on calls to `signal()`.
    /// Returns the previous waker (which could also be the one given) if it
    /// should be immediately signalled because of a concurrent signal.
    /// This method is not thread-safe.
    private func _exchange(_ waker: WakerProtocol) -> WakerProtocol? {
        switch State.compareExchange(&_state, .waiting, .registering, order: .acquire) {
        case .waiting:
            // Lock acquired, save the waker.
            _waker = waker

            // Release the lock. If state transitioned to NOTIFYING in the
            // meantime, someone's called signal() concurrently, so notify the
            // waker immediately.
            switch State.compareExchange(&_state, .registering, .waiting, order: .acqrel, loadOrder: .acquire) {
            case .registering:
                return nil
            case let actual:
                assert(actual == [.registering, .notifying])
                let waker = _waker.take()
                State.store(&_state, .waiting, order: .release)
                return waker
            }

        case .notifying:
            // Currently in the process of signalling the currently set waker.
            // Make sure to notify the new waker as well, given `self.waker`
            // may be obsolete by now.
            return waker

        case let actual:
            // Another thread is concurrently calling register(). This denotes
            // a bug in the caller's code not synchronising access to register().
            assert(
                actual == .registering ||
                    actual == [.registering, .notifying]
            )
            fatalError("concurrent attempt to register waker")
        }
    }

    /// Signals the last registered waker. This method is thread-safe.
    @usableFromInline
    func signal() {
        take()?.signal()
    }

    /// Returns the last registered waker. This method is thread-safe.
    @usableFromInline
    func take() -> WakerProtocol? {
        switch State.fetchOr(&_state, .notifying, order: .acqrel) {
        case .waiting:
            // Lock acquired. Take out the waker before releasing it.
            let waker = _waker.take()
            State.fetchAnd(&_state, .notified, order: .release)
            return waker

        case let actual:
            assert(
                actual == .registering ||
                    actual == [.registering, .notifying] ||
                    actual == .notifying
            )
            return nil
        }
    }
}

#else

@usableFromInline
final class _AtomicWaker: WakerProtocol {
    @usableFromInline let _lock = UnfairLock()
    @usableFromInline var _waker: WakerProtocol?

    @inlinable
    init() {
        #if DEBUG
        print("WARNING: using blocking AtomicWaker")
        #endif
    }

    @inlinable
    func register(_ waker: WakerProtocol) {
        // states are distinct due to exclusive locking,
        // and there is never a need to signal the previous
        // waker like on the atomic version.
        _lock.sync { _waker = waker }
    }

    @inlinable
    func signal() {
        take()?.signal()
    }

    @inlinable
    func take() -> WakerProtocol? {
        return _lock.sync { _waker.take() }
    }
}

#endif
