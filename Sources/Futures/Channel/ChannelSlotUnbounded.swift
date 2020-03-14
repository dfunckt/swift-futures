//
//  ChannelSlotUnbounded.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Channel._Private {
    public struct SlotUnbounded<Item>: _ChannelBufferImplProtocol {
        // The semantics of this buffer (used by Passthrough) are such that
        // in order to get deterministic results, it only makes sense to use
        // it from a single executor -- typically one for the main thread.
        //
        // `Impl` already guarantees thread-safety, so if we changed `_Ref`
        // below to a `SharedValue`, we'd automatically get the ability to
        // use this buffer in a multi-executor context.
        @usableFromInline let _element = Box(Item?.none)

        @inlinable
        init() {}

        @inlinable
        public var supportsMultipleSenders: Bool {
            return false
        }

        @inlinable
        public var isPassthrough: Bool {
            return true
        }

        @inlinable
        public var capacity: Int {
            return Int.max
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
