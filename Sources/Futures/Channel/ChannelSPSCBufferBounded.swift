//
//  ChannelSPSCBufferBounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct SPSCBufferBounded<Item>: _ChannelBufferImplProtocol {
        @usableFromInline let _capacity: Int
        @usableFromInline let _buffer: AtomicSPSCQueue<Item>

        @inlinable
        init(capacity: Int) {
            _capacity = Int(UInt32(capacity))
            _buffer = .init(capacity: max(2, nextPowerOf2(_capacity)))
        }

        @inlinable
        public static var supportsMultipleSenders: Bool {
            return false
        }

        @inlinable
        public static var isPassthrough: Bool {
            return false
        }

        @inlinable
        public static var isBounded: Bool {
            return true
        }

        @inlinable
        public var capacity: Int {
            return _capacity
        }

        @inlinable
        public func push(_ item: Item) {
            let pushed = _buffer.tryPush(item)
            assert(pushed)
        }

        @inlinable
        public func pop() -> Item? {
            return _buffer.pop()
        }
    }
}
