//
//  EventQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesIO
import FuturesPlatform

/// A light-weight type providing a uniform API for the kernel event
/// notification mechanisms in Darwin and Linux. Wraps `kqueue(2)` on
/// Darwin and `epoll(7)` on Linux.
///
///     // Bind a server socket
///     let server = listen("127.0.0.1", port: 0)
///
///     // Connect to the server
///     let stream = connect(server.localAddress)
///
///     // Construct a new event queue and list to store events into
///     let queue = try EventQueue()
///     let events = EventList(capacity: 128)
///
///     // Register the stream with the event queue
///     let streamToken = queue.makeToken(rawValue: 0)
///     try queue.register(
///         handle: stream.handle,
///         token: streamToken,
///         interest: [.read, .write]
///     )
///
///     // Wait for the stream to become ready.
///     // This must happen in a loop to handle spurious wakeups.
///     while true {
///         try queue.wait(&events).get()
///
///         for event in events {
///             if event.token == streamToken, event.isWritable {
///                 // The socket connected
///                 return
///             }
///         }
///     }
///
@usableFromInline
struct EventQueue {
    #if canImport(Darwin)
    @usableFromInline internal typealias Selector = KqueueSelector
    #else
    @usableFromInline internal typealias Selector = EpollSelector
    #endif

    @usableFromInline let _selector: Selector

    @inlinable
    internal init(selector: Selector) {
        _selector = selector
    }

    @inlinable
    internal static func makeEventQueue() -> IOResult<EventQueue> {
        Selector.makeSelector().map(EventQueue.init(selector:))
    }
}

extension EventQueue {
    @usableFromInline internal typealias Token = UInt

    @inlinable
    internal func makeToken(rawValue: UInt) -> Token {
        rawValue
    }

    @inlinable
    internal func register(handle: CInt, token: Token, interest: Interest) -> IOResult<Void> {
        _selector.register(
            handle,
            token: token,
            readable: interest.isReadable,
            writable: interest.isWritable
        )
    }

    @inlinable
    internal func reregister(handle: CInt, token: Token, interest: Interest) -> IOResult<Void> {
        _selector.reregister(
            handle,
            token: token,
            readable: interest.isReadable,
            writable: interest.isWritable
        )
    }

    @inlinable
    internal func deregister(handle: CInt) -> IOResult<Void> {
        _selector.deregister(handle)
    }
}

extension EventQueue {
    /// - Parameter events: A buffer to place events into.
    ///
    /// - Parameter timeout: The maximum amount of time to wait for events.
    ///     Pass `nil` (the default) to wait indefinitely. Pass `0` to not
    ///     wait at all.
    @inlinable
    internal func wait(_ events: inout EventList, timeout: Duration? = nil) -> IOResult<Void> {
        events.withPointerToRawEventList {
            if let timeout = timeout {
                return _selector.select(
                    buffer: $0.baseAddress!,
                    capacity: CInt($0.count),
                    timeout: timeout
                )
            } else {
                return _selector.select(
                    buffer: $0.baseAddress!,
                    capacity: CInt($0.count)
                )
            }
        }
    }

    @inlinable
    internal func duplicate() -> IOResult<EventQueue> {
        _selector.duplicate().map(EventQueue.init(selector:))
    }

    @inlinable
    internal func destroy() {
        _selector.close()
    }
}

extension EventQueue {
    @usableFromInline
    internal struct Waker {
        @usableFromInline let _waker: Selector.Waker

        @inlinable
        init(waker: Selector.Waker) {
            _waker = waker
        }

        @inlinable
        internal func wake() -> IOResult<Void> {
            _waker.wakeup()
        }

        @inlinable
        internal func close() {
            _waker.close()
        }
    }

    @inlinable
    internal func makeWaker(token: Token) -> IOResult<Waker> {
        _selector.makeWaker(token: token).map(Waker.init(waker:))
    }
}
