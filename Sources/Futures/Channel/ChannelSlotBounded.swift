//
//  ChannelSlotBounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Channel._Private {
    public struct SlotBounded<Item>: _ChannelBufferImplProtocol {
        @usableFromInline let _element = Box(Item?.none)

        @inlinable
        init() {}

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
            return 1
        }

        @inlinable
        public func push(_ item: Item) {
            _element.value = item
        }

        @inlinable
        public func pop() -> Item? {
            return _element.value.move()
        }
    }
}
