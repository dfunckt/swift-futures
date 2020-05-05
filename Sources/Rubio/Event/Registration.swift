//
//  Registration.swift
//  Rubio
//
//  Created by Akis Kesoglou on 24/5/20.
//

import Futures
import FuturesIO
import FuturesPlatform
import FuturesSync

@usableFromInline
internal final class Registration {
    @usableFromInline var state: UInt = 0
    @usableFromInline var readiness: Readiness = []

    @usableFromInline weak var driver: Driver?
    @usableFromInline var handle: CInt

    @usableFromInline let reader = AtomicWaker()
    @usableFromInline let writer = AtomicWaker()

    @inlinable
    init(driver: Driver, handle: CInt) {
        self.driver = driver
        self.handle = handle
    }
}

extension Registration {
    @inlinable
    static func fromToken(_ token: UInt) -> Self? {
        guard let ptr = UnsafeRawPointer(bitPattern: token) else {
            return nil
        }
        return Unmanaged<Self>.fromOpaque(ptr).takeUnretainedValue()
    }

    var token: UInt {
        // Make an unmanaged unowned reference to the instance
        // and use the address as a token.
        .init(bitPattern: Unmanaged.passUnretained(self).toOpaque())
    }
}

extension Registration {
    func isReady(for interest: Interest) -> Bool {
        let mask = readiness.rawValue & Interest.all.rawValue // exclude HUP
        return mask & interest.rawValue != 0
    }

    func clearReady(for interest: Interest, waker: WakerProtocol) {
        // Build the bitfield of possible readiness states for the given
        // interest and register the waker for further notifications
        var mask: UInt8 = 0
        if interest.isReadable {
            reader.register(waker)
            mask |= Readiness.readable.rawValue // include HUP
        }
        if interest.isWritable {
            writer.register(waker)
            mask |= Readiness.writable.rawValue // include HUP
        }

        // Clear the current readiness state *except* for read/write HUP
        // because they are final states and are never transitioned out of,
        // and both readiness streams should be able to observe these states.
        self.readiness.rawValue &= ~interest.rawValue

        let readiness = Readiness(rawValue: mask & self.readiness.rawValue)
        if readiness.isReadable {
            reader.signal()
        }
        if readiness.isWritable {
            writer.signal()
        }
    }

    func cancel() -> IOResult<Void> {
        guard let driver = driver else {
            return .success(())
        }
        return driver.suspendSource(self).map {
            driver.removeSource(self)
        }
    }
}
