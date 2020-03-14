//
//  AtomicMPMCQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

/// A bounded FIFO queue that is safe to share among multiple producers and
/// consumers.
///
/// This is an implementation of "bounded MPMC queue" from 1024cores.net.
public final class AtomicMPMCQueue<Element>: AtomicQueueProtocol {
    @usableFromInline let _buffer: _AtomicBuffer<Element>
    @usableFromInline let _mask: Int
    @usableFromInline var _head: AtomicInt.RawValue = 0 // producers
    @usableFromInline var _tail: AtomicInt.RawValue = 0 // consumers

    @inlinable
    public init(capacity: Int) {
        precondition(capacity >= 2)
        precondition(isPowerOf2(capacity))
        _mask = capacity - 1
        _buffer = .create(capacity: capacity)
    }

    @inlinable
    public func tryPush(_ value: Element) -> Bool {
        return _buffer.withUnsafeMutablePointerToElements { elements in
            var backoff = Backoff()
            while true {
                let i = AtomicInt.load(&_head, order: .relaxed)
                let s = AtomicInt.load(&elements[i & _mask].sequence, order: .acquire)
                let diff = s - i

                if diff == 0 {
                    if i == AtomicInt.compareExchangeWeak(&_head, i, i + 1, order: .relaxed) {
                        elements[i & _mask].value = value
                        AtomicInt.store(&elements[i & _mask].sequence, i + 1, order: .release)
                        return true
                    }
                } else if diff < 0 {
                    // full
                    return false
                }

                backoff.yield()
            }
        }
    }

    @inlinable
    public func pop() -> Element? {
        return _buffer.withUnsafeMutablePointerToElements { elements in
            var backoff = Backoff()
            while true {
                let i = AtomicInt.load(&_tail, order: .relaxed)
                let s = AtomicInt.load(&elements[i & _mask].sequence, order: .acquire)
                let diff = s - (i + 1)

                if diff == 0 {
                    if i == AtomicInt.compareExchangeWeak(&_tail, i, i + 1, order: .relaxed) {
                        let value = elements[i & _mask].value
                        elements[i & _mask].value = nil
                        AtomicInt.store(&elements[i & _mask].sequence, i + (_mask + 1), order: .release)
                        return value
                    }
                } else if diff < 0 {
                    // empty
                    return nil
                }

                backoff.yield()
            }
        }
    }
}
