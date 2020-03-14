//
//  Park.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Dispatch
import FuturesSync

public protocol ParkProtocol {
    associatedtype Waker: WakerProtocol

    var waker: Waker { get }

    nonmutating func park()
}

// MARK: -

public struct ThreadPark: ParkProtocol {
    public final class Waker {
        @usableFromInline static let IDLE: UInt = 0
        @usableFromInline static let PARKED: UInt = 1
        @usableFromInline static let NOTIFIED: UInt = 2

        // used to prevent spurious wakeups due to the semaphore's value
        // accumulating via multiple signals by effectively coalescing them
        @usableFromInline var _state: AtomicUInt.RawValue = 0

        // used to park/unpark the thread
        @usableFromInline let _semaphore = DispatchSemaphore(value: 0)

        @inlinable
        init() {
            AtomicUInt.initialize(&_state, to: Self.IDLE)
        }
    }

    @usableFromInline let _waker = Waker()

    @inlinable
    public init() {}

    @inlinable
    public var waker: Waker {
        return _waker
    }

    @inlinable
    public func park() {
        _waker._park()
    }
}

extension ThreadPark: Equatable {
    @_transparent
    public static func == (lhs: ThreadPark, rhs: ThreadPark) -> Bool {
        lhs.waker === rhs.waker
    }
}

extension ThreadPark.Waker: WakerProtocol {
    @inlinable
    public func signal() {
        switch AtomicUInt.exchange(&_state, Self.NOTIFIED) {
        case Self.NOTIFIED:
            // ignore this one; already signalled
            return

        case Self.IDLE:
            // ignore this one as well; `wait()` will observe
            // the notification and not block at all
            return

        case Self.PARKED:
            _semaphore.signal()

        default:
            fatalError("unreachable")
        }
    }
}

extension ThreadPark.Waker {
    @inlinable
    func _park() {
        switch AtomicUInt.compareExchange(&_state, Self.IDLE, Self.PARKED) {
        case Self.NOTIFIED:
            // already signalled; no need to block,
            // just consume the notification
            let prev = AtomicUInt.exchange(&_state, Self.IDLE)
            assert(prev == Self.NOTIFIED)
            return

        case Self.IDLE:
            // not signalled yet; block the thread.
            // There's potential for a race condition here that the counting
            // semaphore protects us against: after we changed the state above
            // and by the time we get to block the thread, someone may call
            // `signal()` on us and that notification would be lost. The
            // semaphore however "remembers" this signal and attempting to
            // wait on it results in `wait()` consuming that signal and
            // immediately returning (which is pretty much identical behavior
            // to what we do here as well).
            _semaphore.wait()

            while Self.NOTIFIED != AtomicUInt.compareExchange(&_state, Self.NOTIFIED, Self.IDLE) {
                Atomic.hardwarePause()
            }

        default:
            fatalError("unreachable")
        }
    }
}
