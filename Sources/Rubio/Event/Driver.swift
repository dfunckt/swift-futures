//
//  Driver.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesIO
import FuturesPlatform
import FuturesSync

@usableFromInline let WAKER_TOKEN: UInt = 0

@usableFromInline
internal final class Driver {
    @usableFromInline let _selector: EventQueue
    @usableFromInline var _events: EventList

    @usableFromInline let _cache = AtomicUnboundedMPSCQueue<Registration>()

    @inlinable
    internal init(capacity: Int = 1_024) throws {
        _selector = try EventQueue.makeEventQueue().get()
        _events = .init(capacity: capacity)
    }

    deinit {
        _events.deallocate()
        _selector.destroy()
    }
}

extension Driver {
    @inlinable
    internal func poll<C: ClockProtocol>(until date: Instant<C>? = nil) -> IOResult<Void> {
        // If we're given a date that is in the past,
        // force a single poll without blocking.
        let shouldPollOnce = date != nil && date!.elapsedDuration() >= 0

        // Do this in a loop to handle spurious wakeups.
        retry: while true {
            let remainingDuration: Duration?

            if shouldPollOnce {
                // Poll once without blocking.
                remainingDuration = 0
            } else if let date = date {
                let dt = date.elapsedDuration()
                if dt >= 0 {
                    // Timeout expired
                    return .success(())
                }
                remainingDuration = -dt
            } else {
                // Block indefinitely
                remainingDuration = nil
            }

            switch _selector.wait(&_events, timeout: remainingDuration) {
            case .success:
                break

            case .failure(EINTR):
                assert(_events.isEmpty)
                continue retry

            case .failure(let error):
                assert(_events.isEmpty)
                return .failure(error)
            }

            for event in _events {
                if event.token == WAKER_TOKEN {
                    // This is a notification for the selector to wakeup.
                    // Consume it and continue with the rest of the events.
                    continue
                }

                // Resolve Registration from event.token
                guard let registration = Registration.fromToken(event.token) else {
                    continue
                }

                // Merge new readiness into registration
                registration.readiness.rawValue |= event.readiness.rawValue

                // Signal reader and/or writer if needed
                let readiness = registration.readiness
                if readiness.isWritable {
                    registration.writer.signal()
                }
                if readiness.isReadable {
                    registration.reader.signal()
                }
            }

            _events.reset()

            return .success(())
        }
    }
}

extension Driver {
    func addSource(handle: CInt, interest: Interest) -> IOResult<Registration> {
        let registration: Registration
        if let cachedRegistration = _cache.pop() {
            // Reset and reuse a cached registration
            registration = cachedRegistration
            registration.handle = handle
            // TODO: bump generation
        } else {
            registration = .init(driver: self, handle: handle)
        }
        let result = _selector.register(
            handle: registration.handle,
            token: registration.token,
            interest: interest
        )
        return result.map { registration }
    }

    func resumeSource(_ registration: Registration, interest: Interest) -> IOResult<Void> {
        _selector.reregister(
            handle: registration.handle,
            token: registration.token,
            interest: interest
        )
    }

    func suspendSource(_ registration: Registration) -> IOResult<Void> {
        _selector.deregister(handle: registration.handle)
    }

    func removeSource(_ registration: Registration) {
        registration.readiness = []
        registration.reader.clear()
        registration.writer.clear()
        _cache.push(registration)
    }
}
