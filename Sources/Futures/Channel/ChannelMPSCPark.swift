//
//  ChannelMPSCPark.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct MPSCPark: _ChannelParkImplProtocol {
        @usableFromInline let _closing = AtomicBool(false)
        @usableFromInline let _lock = UnfairLock()
        @usableFromInline let _wakers = AtomicUnboundedMPSCQueue<WakerProtocol>()
        @usableFromInline let _wakersFlush = AtomicUnboundedMPSCQueue<WakerProtocol>()

        @inlinable
        init() {}

        @inlinable
        public func park(_ waker: WakerProtocol) {
            _wakers.push(waker)
        }

        @inlinable
        public func notifyOne() {
            guard !_closing.load() else {
                return
            }
            _lock.trySync {
                if let sender = _wakers.pop() {
                    sender.signal()
                }
            }
        }

        @inlinable
        public func parkFlush(_ waker: WakerProtocol) {
            _wakersFlush.push(waker)
        }

        @inlinable
        public func notifyFlush() {
            guard !_closing.load() else {
                return
            }
            let senders: [WakerProtocol]? = _lock.trySync {
                var senders = [WakerProtocol]()
                while let sender = _wakersFlush.pop() {
                    senders.append(sender)
                }
                return senders
            }
            if let senders = senders {
                for sender in senders {
                    sender.signal()
                }
            }
        }

        @inlinable
        public func notifyAll() {
            guard !_closing.exchange(true) else {
                return
            }
            let senders: [WakerProtocol] = _lock.sync {
                var senders = [WakerProtocol]()
                while let sender = _wakersFlush.pop() {
                    senders.append(sender)
                }
                while let sender = _wakers.pop() {
                    senders.append(sender)
                }
                return senders
            }
            for sender in senders {
                sender.signal()
            }
        }
    }
}
