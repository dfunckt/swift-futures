//
//  Waker.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

public protocol WakerProtocol: AnyObject {
    func signal()
}

public final class AnyWaker: WakerProtocol {
    private let _signalFn: () -> Void

    public init(_ signalHandler: @escaping () -> Void) {
        _signalFn = signalHandler
    }

    public func signal() {
        _signalFn()
    }
}

// MARK: -

// set to `false` to replace AtomicWaker with a simple
// lock-based waker that is useful for debugging.
#if true

/// A primitive for synchronizing attempts to wake a task.
public final class AtomicWaker: WakerProtocol {
    @usableFromInline struct State: AtomicBitset {
        @usableFromInline let rawValue: AtomicUInt.RawValue

        @inlinable
        init(rawValue: AtomicUInt.RawValue) {
            self.rawValue = rawValue
        }

        @inlinable static var idle: State { 0 }
        @inlinable static var registering: State { 0b01 }
        @inlinable static var notifying: State { 0b10 }
    }

    @usableFromInline var _state = State.idle.rawValue
    @usableFromInline var _waker: WakerProtocol?

    @inlinable
    public init() {
        State.initialize(&_state, to: .idle)
    }

    /// Register a waker to be notified on calls to `signal()`.
    /// This method must not be called concurrently.
    @inlinable
    public func register(_ waker: WakerProtocol) {
        switch State.compareExchange(&_state, .idle, .registering, order: .acquire) {
        case .idle:
            // Lock acquired, save the waker.
            _waker = waker

            // Release the lock. If state transitioned to NOTIFYING in the
            // meantime, someone's called signal() concurrently, so notify the
            // waker immediately.
            switch State.compareExchange(&_state, .registering, .idle, order: .acqrel, loadOrder: .acquire) {
            case .registering:
                return
            case let actual:
                assert(actual == .registering | .notifying)
                State.store(&_state, .idle, order: .release)
                waker.signal()
            }

        case .notifying:
            // Currently in the process of signalling the currently set waker.
            // Make sure to notify the new waker as well, given `self.waker`
            // may be obsolete by now.
            waker.signal()
            // This is a lot like spinning, so give other threads
            // a chance as well
            Atomic.preemptionYield(0)

        case let actual:
            // Another thread is concurrently calling register(). This denotes
            // a bug in the caller's code not synchronising access to register().
            assert(actual == .registering || actual == .registering | .notifying)
            fatalError("concurrent attempt to register waker")
        }
    }

    /// Clears the registered waker, if any.
    ///
    /// This method can be called concurrently.
    @inlinable
    public func clear() {
        _ = move()
    }

    /// Signals the last registered waker.
    ///
    /// This method can be called concurrently.
    @inlinable
    public func signal() {
        move()?.signal()
    }

    /// Returns the last registered waker.
    ///
    /// This method can be called concurrently.
    @inlinable
    public func move() -> WakerProtocol? {
        switch State.fetchOr(&_state, .notifying, order: .acqrel) {
        case .idle:
            // Lock acquired. Take out the waker before releasing it.
            let waker = _waker.move()
            State.fetchXor(&_state, .notifying, order: .release)
            return waker

        case let actual:
            assert(
                actual == .registering ||
                    actual == .registering | .notifying ||
                    actual == .notifying
            )
            return nil
        }
    }
}

#else
private let _warnBlockingWaker: Void = {
    print("WARNING: using blocking AtomicWaker")
}()

/// :nodoc:
public final class AtomicWaker: WakerProtocol {
    @usableFromInline let _lock = UnfairLock()
    @usableFromInline var _waker: WakerProtocol?

    public init() {
        _warnBlockingWaker
    }

    @inlinable
    public func register(_ waker: WakerProtocol) {
        // states are distinct due to exclusive locking,
        // and there is never a need to signal the previous
        // waker like on the atomic version.
        _lock.sync { _waker = waker }
    }

    @inlinable
    public func signal() {
        move()?.signal()
    }

    @inlinable
    public func move() -> WakerProtocol? {
        return _lock.sync { _waker.move() }
    }
}

#endif

// MARK: -

@usableFromInline
internal struct AtomicWakerQueue {
    @usableFromInline
    final class Waker {
        @usableFromInline var _next: AtomicReference<Waker>.RawValue = 0
        @usableFromInline var _cancelled: AtomicBool.RawValue = false
        @usableFromInline var _waker: WakerProtocol?

        @inlinable
        init(waker: WakerProtocol? = nil) {
            _waker = waker
        }
    }

    @usableFromInline let _queue: AtomicList<Waker>

    @inlinable
    init() {
        _queue = .init(stub: .init(waker: nil))
    }
}

extension AtomicWakerQueue {
    @inlinable
    func push(_ waker: WakerProtocol) -> Waker {
        let waker = Waker(waker: waker)
        _queue.enqueue(waker)
        return waker
    }

    @inlinable
    func signal() {
        while let waker = _queue.dequeue() {
            if waker.signal() {
                return
            }
            Atomic.hardwarePause()
        }
    }

    @inlinable
    func broadcast() {
        while let waker = _queue.dequeue() {
            _ = waker.signal()
            Atomic.hardwarePause()
        }
    }

    @inlinable
    func clear() {
        while let waker = _queue.dequeue() {
            waker.cancel()
            Atomic.hardwarePause()
        }
    }
}

extension AtomicWakerQueue.Waker: Cancellable {
    @inlinable
    func cancel() {
        guard !AtomicBool.exchange(&_cancelled, true, order: .acqrel) else {
            return
        }
        _waker = nil
    }

    @inlinable
    func signal() -> Bool {
        guard !AtomicBool.exchange(&_cancelled, true, order: .acqrel) else {
            return false
        }
        guard let waker = _waker.move() else {
            fatalError("expected non-nil waker")
        }
        waker.signal()
        return true
    }
}

extension AtomicWakerQueue.Waker: AtomicListNode {
    @inlinable
    @_transparent
    func withAtomicPointerToNextNode<R>(_ block: (AtomicReference<AtomicWakerQueue.Waker>.Pointer) -> R) -> R {
        block(&_next)
    }
}
