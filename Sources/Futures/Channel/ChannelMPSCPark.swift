//
//  ChannelMPSCPark.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct MPSCPark: _ChannelParkImplProtocol {
        @usableFromInline let _wakers = AtomicWakerQueue()
        @usableFromInline let _wakersFlush = AtomicWakerQueue()

        @inlinable
        init() {}

        @inlinable
        public func park(_ waker: WakerProtocol) -> Cancellable {
            _wakers.push(waker)
        }

        @inlinable
        public func notifyOne() {
            _wakers.signal()
        }

        @inlinable
        public func notifyAll() {
            _wakers.broadcast()
        }

        @inlinable
        public func parkFlush(_ waker: WakerProtocol) -> Cancellable {
            _wakersFlush.push(waker)
        }

        @inlinable
        public func notifyFlush() {
            _wakersFlush.broadcast()
        }
    }
}
