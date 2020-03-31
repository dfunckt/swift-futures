//
//  AtomicSPMCQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

/// A bounded FIFO queue that is safe to share among a single producer and
/// multiple consumers.
public struct AtomicSPMCQueue<Element>: AtomicQueueProtocol {
    @usableFromInline let _buffer: _AtomicBuffer<Element>

    @inlinable
    public init(capacity: Int) {
        _buffer = .create(capacity: capacity)
    }

    @inlinable
    public var capacity: Int {
        _buffer._capacity
    }

    @inlinable
    public func tryPush(_ element: Element) -> Bool {
        return _buffer._tryPush(element)
    }

    @inlinable
    public func pop() -> Element? {
        return _buffer._popConcurrent()
    }
}
