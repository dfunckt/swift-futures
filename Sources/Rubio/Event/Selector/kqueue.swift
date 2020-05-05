//
//  kqueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)

import FuturesIO
import FuturesPlatform

@usableFromInline
struct KqueueSelector {
    @usableFromInline let _handle: CInt

    @inlinable
    init(handle: CInt) {
        _handle = handle
    }

    @inlinable
    static func makeSelector() -> IOResult<KqueueSelector> {
        IOResult(syscall: kqueue()).map(KqueueSelector.init(handle:))
        // We don't need to set the CLOEXEC flag. From kqueue manpage:
        // "The queue is not inherited by a child created with fork(2)."
    }
}

// MARK: - Event -

extension KqueueSelector {
    @usableFromInline typealias Event = kevent

    @inlinable
    @_transparent
    static func token(for event: Event) -> UInt {
        .init(bitPattern: event.udata)
    }

    @inlinable
    @_transparent
    static func isReadReady(_ event: Event) -> Bool {
        event.filter == EVFILT_READ || event.filter == EVFILT_USER
    }

    @inlinable
    @_transparent
    static func isReadClosed(_ event: Event) -> Bool {
        event.filter == EVFILT_READ && event.flags & CUnsignedShort(EV_EOF) != 0
    }

    @inlinable
    @_transparent
    static func isWriteReady(_ event: Event) -> Bool {
        event.filter == EVFILT_WRITE
    }

    @inlinable
    @_transparent
    static func isWriteClosed(_ event: Event) -> Bool {
        event.filter == EVFILT_WRITE && event.flags & CUnsignedShort(EV_EOF) != 0
    }

    @inlinable
    @_transparent
    static func isError(_ event: Event) -> Bool {
        (event.flags & CUnsignedShort(EV_ERROR) != 0) ||
            // manpage: "If the read direction of the socket has shutdown,
            // then the filter also sets EV_EOF in `flags`, and returns the
            // socket error (if any) in `fflags`."
            (event.flags & CUnsignedShort(EV_EOF) != 0) && event.fflags != 0
    }
}

// MARK: - Poll -

extension KqueueSelector {
    @inlinable
    func select(buffer: UnsafeMutablePointer<Event>, capacity: CInt) -> IOResult<CInt> {
        IOResult(syscall: kevent(_handle, nil, 0, buffer, capacity, nil))
    }

    @inlinable
    func select(buffer: UnsafeMutablePointer<Event>, capacity: CInt, timeout: Duration) -> IOResult<CInt> {
        var ts = timeout.timespec
        return IOResult(syscall: kevent(_handle, nil, 0, buffer, capacity, &ts))
    }

    @inlinable
    func duplicate() -> IOResult<KqueueSelector> {
        IOResult(syscall: fcntl(_handle, F_DUPFD_CLOEXEC)).map(
            KqueueSelector.init(handle:)
        )
    }

    @inlinable
    func close() {
        _ = FuturesPlatform.close(_handle)
    }
}

// MARK: - Registration -

extension KqueueSelector {
    @inlinable
    func register(_ descriptor: CInt, token: UInt, readable: Bool, writable: Bool) -> IOResult<Void> {
        var events = (Event(), Event())

        return withUnsafeMutablePointer(to: &events) {
            $0.withMemoryRebound(to: Event.self, capacity: 2) { buffer in
                var count = 0

                let flags = EV_CLEAR | EV_RECEIPT | EV_ADD
                if readable {
                    buffer[count] = _makeEvent(descriptor, token, EVFILT_READ, flags)
                    count += 1
                }
                if writable {
                    buffer[count] = _makeEvent(descriptor, token, EVFILT_WRITE, flags)
                    count += 1
                }
                if count == 0 {
                    return .success(())
                }
                // Limit the buffer up to `count` events
                let ptr = UnsafeMutableBufferPointer(start: buffer, count: count)

                // kevent will still report events on a file descriptor,
                // telling us that it's readable/hup at least after we've
                // done this registration. As a result we just ignore `EPIPE`
                // here instead of propagating it.
                // FIXME: avoid allocation (?) for error list
                return _register(_handle, events: ptr, ignoringErrors: [EPIPE])
            }
        }
    }

    @inlinable
    func reregister(_ descriptor: CInt, token: UInt, readable: Bool, writable: Bool) -> IOResult<Void> {
        let flags = EV_CLEAR | EV_RECEIPT
        let readFlags = flags | (readable ? EV_ADD : EV_DELETE)
        let writeFlags = flags | (writable ? EV_ADD : EV_DELETE)

        // Since there is no way to check with which interests the fd was
        // registered we modify both readable and writable, adding it when
        // required and removing it otherwise, ignoring the ENOENT error when
        // it comes up. The ENOENT error informs us that a filter we're trying
        // to remove wasn't there in first place, but we don't really care
        // since our goal is accomplished.
        var events = (
            _makeEvent(descriptor, token, EVFILT_READ, readFlags),
            _makeEvent(descriptor, token, EVFILT_WRITE, writeFlags)
        )

        // For the explanation of ignoring `EPIPE` see `register()` above.
        return withUnsafeMutablePointer(to: &events) {
            $0.withMemoryRebound(to: Event.self, capacity: 2) { buffer in
                let ptr = UnsafeMutableBufferPointer(start: buffer, count: 2)
                // FIXME: avoid allocation (?) for error list
                return _register(_handle, events: ptr, ignoringErrors: [EPIPE, ENOENT])
            }
        }
    }

    @inlinable
    func deregister(_ descriptor: CInt) -> IOResult<Void> {
        let flags = EV_DELETE | EV_RECEIPT

        // Since there is no way to check with which interests the fd was
        // registered we remove both readable and writable, and ignore the
        // ENOENT error when it comes up. The ENOENT error informs us that
        // the filter wasn't there in first place, but we don't really care
        // since our goal is to remove it.
        var events = (
            _makeEvent(descriptor, 0, EVFILT_READ, flags),
            _makeEvent(descriptor, 0, EVFILT_WRITE, flags)
        )

        // For the explanation of ignoring `EPIPE` see `register()` above.
        return withUnsafeMutablePointer(to: &events) {
            $0.withMemoryRebound(to: Event.self, capacity: 2) { buffer in
                let ptr = UnsafeMutableBufferPointer(start: buffer, count: 2)
                // FIXME: avoid allocation (?) for error list
                return _register(_handle, events: ptr, ignoringErrors: [EPIPE, ENOENT])
            }
        }
    }
}

// MARK: - Waker -

extension KqueueSelector {
    @usableFromInline
    internal struct Waker {
        @usableFromInline internal let queue: CInt
        @usableFromInline internal let token: UInt

        @inlinable
        init(queue: CInt, token: UInt) {
            self.queue = queue
            self.token = token
        }
    }
}

extension KqueueSelector {
    @inlinable
    internal func makeWaker(token: UInt) -> IOResult<Waker> {
        // Duplicate the queue descriptor
        IOResult(syscall: fcntl(_handle, F_DUPFD_CLOEXEC)).flatMap { kq in
            let flags = EV_ADD | EV_CLEAR | EV_RECEIPT
            var event = _makeEvent(0, token, EVFILT_USER, flags)

            // Register the waker
            return withUnsafeMutablePointer(to: &event) {
                IOResult(syscall: kevent(kq, $0, 1, $0, 1, nil))
            }
            .flatMap { _ in
                if _hasError(event) {
                    return .failure(IOError(code: .init(event.data)))
                } else {
                    return .success(kq)
                }
            }
            .mapError {
                // Ensure the descriptor is not leaked if
                // there was an error registering it
                _ = FuturesPlatform.close(kq)
                return $0
            }
        }
        .map {
            .init(queue: $0, token: token)
        }
    }
}

extension KqueueSelector.Waker {
    @inlinable
    internal func wakeup() -> IOResult<Void> {
        let flags = EV_ADD | EV_RECEIPT
        let fflags = NOTE_TRIGGER
        var event = _makeEvent(0, token, EVFILT_USER, flags, fflags)
        return withUnsafeMutablePointer(to: &event) {
            IOResult(syscall: kevent(queue, $0, 1, $0, 1, nil))
        }
        .flatMap { _ in
            if _hasError(event) {
                return .failure(IOError(code: .init(event.data)))
            } else {
                return .success(())
            }
        }
    }

    @inlinable
    internal func close() {
        _ = FuturesPlatform.close(queue)
    }
}

// MARK: - Private -

@usableFromInline
@_transparent
func _makeEvent(
    _ descriptor: CInt,
    _ token: UInt,
    _ filter: CInt,
    _ flags: CInt,
    _ fflags: CInt = 0
) -> KqueueSelector.Event {
    .init(
        ident: UInt(descriptor),
        filter: CShort(filter),
        flags: CUnsignedShort(flags),
        fflags: CUnsignedInt(fflags),
        data: 0,
        udata: UnsafeMutableRawPointer(bitPattern: token)
    )
}

/// Register `changes` with kqueue.
@usableFromInline
@_transparent
func _register(
    _ queue: CInt,
    events: UnsafeMutableBufferPointer<KqueueSelector.Event>,
    ignoringErrors codes: [CInt] = []
) -> IOResult<Void> {
    IOResult(
        syscall: kevent(
            queue,
            events.baseAddress, CInt(events.count),
            events.baseAddress, CInt(events.count),
            nil
        )
    )
    .map { _ in }
    .flatMapError {
        // It's safe to ignore EINTR; as per manpage:
        // "When kevent() call fails with EINTR error, all
        // changes in the changelist have been applied"
        if $0 != EINTR {
            return .failure($0)
        } else {
            return .success(())
        }
    }
    .flatMap {
        // Check all events for possible errors and throw the first found.
        for event in events {
            let result = CInt(event.data)
            if _hasError(event), !codes.contains(result) {
                return .failure(IOError(code: result))
            }
        }
        return .success(())
    }
}

@usableFromInline
@_transparent
func _hasError(_ event: KqueueSelector.Event) -> Bool {
    event.flags & CUnsignedShort(EV_ERROR) != 0 && event.data != 0
}

#endif
