//
//  AtomicSPMCQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

/// A bounded FIFO queue that is safe to share among a single producer and
/// multiple consumers.
///
/// This is an implementation of "bounded MPMC queue" from 1024cores.net, with
/// a modification on `push` to remove synchronisation.
public final class AtomicSPMCQueue<Element>: AtomicQueueProtocol {
    @usableFromInline let _buffer: _AtomicBuffer<Element>
    @usableFromInline let _mask: Int
    @usableFromInline var _head = 0 // producer
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
                let i = _head
                let s = Atomic.load(&elements[i & _mask].sequence, order: .acquire)
                let diff = s - i

                if diff == 0 {
                    _head += 1
                    elements[i & _mask].value = value
                    Atomic.store(&elements[i & _mask].sequence, i + 1, order: .release)
                    return true
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
                let i = Atomic.load(&_tail, order: .relaxed)
                let s = Atomic.load(&elements[i & _mask].sequence, order: .acquire)
                let diff = s - (i + 1)

                if diff == 0 {
                    if i == Atomic.compareExchangeWeak(&_tail, i, i + 1, order: .relaxed) {
                        let value = elements[i & _mask].value
                        elements[i & _mask].value = nil
                        Atomic.store(&elements[i & _mask].sequence, i + (_mask + 1), order: .release)
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