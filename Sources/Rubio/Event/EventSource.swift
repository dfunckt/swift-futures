//
//  EventSource.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesIO
import FuturesPlatform

internal enum IOResource<Source: EventSource> {
    case pending(Source)
    case running(Source, Registration)
    case suspended(Source, Registration)
    case cancelled
}

public protocol EventSource {
    var ioHandle: CInt { get }
}

public struct Evented<Source: EventSource> {
    public let source: Source
    public let interest: Interest

    private var registration: Registration?

    public init(source: Source, interest: Interest) {
        self.source = source
        self.interest = interest
    }
}

extension Evented {
    public func suspend() {}
    public func resume() {}
    public func cancel() {}
}

extension Evented {
    internal mutating func _ensureRegistered(_ context: inout Context) -> IOResult<Registration> {
        if let registration = self.registration {
            return .success(registration)
        }

        guard let driver = context.io else {
            fatalError("cannot perform I/O outside the runtime")
        }

        switch driver.addSource(handle: source.ioHandle, interest: interest) {
        case .success(let registration):
            self.registration = registration
            return .success(registration)
        case .failure(let error):
            return .failure(error)
        }
    }
}

extension Evented {
    public mutating func whenReady<T>(
        _ context: inout Context,
        interest: Interest,
        perform block: (Source) -> IOResult<T>
    ) -> Poll<IOResult<T>> {
        assert(
            self.interest.rawValue & interest.rawValue == interest.rawValue,
            "cannot poll for readiness without associated interest"
        )

        switch _ensureRegistered(&context) {
        case .success(let registration):
            guard registration.isReady(for: interest) else {
                return .pending
            }
            switch block(source) {
            case .failure(EWOULDBLOCK):
                registration.clearReady(for: interest, waker: context.waker)
                return .pending
            case let result:
                return .ready(result)
            }

        case .failure(let error):
            return .ready(.failure(error))
        }
    }
}

extension Evented: InputStream where Source: RawInputStream {
    public mutating func pollRead(
        _ context: inout Context,
        into buffer: IOMutableBufferPointer
    ) -> Poll<IOResult<Int>> {
        whenReady(&context, interest: .read) {
            $0.tryRead(into: buffer)
        }
    }
}

extension Evented: OutputStream where Source: RawOutputStream {
    public mutating func pollWrite(
        _ context: inout Context,
        from buffer: IOBufferPointer
    ) -> Poll<IOResult<Int>> {
        whenReady(&context, interest: .write) {
            $0.tryWrite(from: buffer)
        }
    }

    public mutating func pollFlush(_ context: inout Context) -> Poll<IOResult<Void>> {
        whenReady(&context, interest: .write) {
            $0.tryFlush()
        }
    }

    public mutating func pollClose(_ context: inout Context) -> Poll<IOResult<Void>> {
        // Ensure the source is always closed
        let result = source.tryClose()
        // Cancel the registration, if there's one
        if let r = registration {
            registration = nil
            return .ready(r.cancel().flatMap { result })
        }
        return .ready(result)
    }
}
