//
//  ChannelSlotUnbounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    public struct SlotUnbounded<Item>: _ChannelBufferImplProtocol {
        @usableFromInline let _element = Mutex(Item?.none)

        @inlinable
        init() {}

        @inlinable
        public static var isPassthrough: Bool {
            return true
        }

        @inlinable
        public static var isBounded: Bool {
            return false
        }

        @inlinable
        public var capacity: Int {
            return 1
        }

        @inlinable
        public func push(_ item: Item) {
            _element.value = item
        }

        @inlinable
        public func pop() -> Item? {
            return _element.move()
        }
    }
}
