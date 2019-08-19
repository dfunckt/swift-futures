//
//  ChannelMPSCBufferUnbounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct MPSCBufferUnbounded<Item>: _ChannelBufferImplProtocol {
        @usableFromInline let _buffer = AtomicUnboundedMPSCQueue<Item>()

        @inlinable
        init() {}

        @inlinable
        public var supportsMultipleSenders: Bool {
            return true
        }

        @inlinable
        public var isPassthrough: Bool {
            return false
        }

        @inlinable
        public var capacity: Int {
            return Int.max
        }

        @inlinable
        public func push(_ item: Item) {
            _buffer.push(item)
        }

        @inlinable
        public func pop() -> Item? {
            return _buffer.pop()
        }
    }
}
