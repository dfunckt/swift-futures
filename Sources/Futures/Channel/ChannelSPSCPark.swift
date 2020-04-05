//
//  ChannelSPSCPark.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Channel._Private {
    public struct SPSCPark: _ChannelParkImplProtocol {
        @usableFromInline
        struct Waker {
            @usableFromInline let _waker: AtomicWaker

            @inlinable
            init(_ waker: AtomicWaker) {
                _waker = waker
            }
        }

        @usableFromInline let _waker = AtomicWaker()

        @inlinable
        init() {}

        @inlinable
        public func park(_ waker: WakerProtocol) -> Cancellable {
            _waker.register(waker)
            return Waker(_waker)
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
        public func parkFlush(_ waker: WakerProtocol) -> Cancellable {
            _waker.register(waker)
            return Waker(_waker)
        }

        @inlinable
        public func notifyFlush() {
            _waker.signal()
        }
    }
}

extension Channel._Private.SPSCPark.Waker: Cancellable {
    @inlinable
    func cancel() {
        _waker.clear()
    }
}
