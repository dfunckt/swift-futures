//
//  ChannelSPSCPark.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Channel._Private {
    public struct SPSCPark: _ChannelParkImplProtocol {
        @usableFromInline let _waker = AtomicWaker()

        @inlinable
        init() {}

        @inlinable
        public func park(_ waker: WakerProtocol) {
            _waker.register(waker)
        }

        @inlinable
        public func notifyOne() {
            _waker.signal()
        }

        @inlinable
        public func notifyAll() {
            _waker.signal()
        }

        @inlinable
        public func parkFlush(_ waker: WakerProtocol) {
            _waker.register(waker)
        }

        @inlinable
        public func notifyFlush() {
            _waker.signal()
        }
    }
}
