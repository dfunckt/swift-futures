//
//  ChannelSPSCBufferBounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct SPSCBufferBounded<Item>: _ChannelBufferImplProtocol {
        @usableFromInline let _buffer: AtomicSPSCQueue<Item>

        @inlinable
        init(capacity: Int) {
            _buffer = .init(capacity: capacity)
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
            return _buffer.capacity
        }

        @inlinable
        public func push(_ item: Item) {
            let result = _buffer.tryPush(item)
            assert(result, "expected push to succeed, but buffer is at capacity")
        }

        @inlinable
        public func pop() -> Item? {
            return _buffer.pop()
        }
    }
}
