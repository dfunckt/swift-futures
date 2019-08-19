//
//  AtomicQueueBuffer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

@usableFromInline
struct _AtomicBufferHead {
    @usableFromInline let capacity: Int

    @inlinable
    init(capacity: Int) {
        self.capacity = capacity
    }
}

@usableFromInline
struct _AtomicBufferSlot<T> {
    @usableFromInline var sequence: AtomicInt.RawValue = 0
    @usableFromInline var value: T?

    @inlinable
    init(_ sequence: AtomicInt.RawValue) {
        Atomic.initialize(&self.sequence, to: sequence)
    }
}

@usableFromInline
final class _AtomicBuffer<T>: ManagedBuffer<_AtomicBufferHead, _AtomicBufferSlot<T>> {
    @inlinable
    static func create(capacity: Int) -> _AtomicBuffer {
        let buffer = create(minimumCapacity: capacity) { _ in
            .init(capacity: capacity)
        }
        buffer.withUnsafeMutablePointerToElements {
            for s in 0..<capacity {
                $0.advanced(by: s).initialize(to: .init(s))
            }
        }
        return unsafeDowncast(buffer, to: _AtomicBuffer.self)
    }

    @inlinable
    deinit {
        withUnsafeMutablePointers {
            $1.deinitialize(count: $0.pointee.capacity)
            $0.deinitialize(count: 1)
        }
    }
}
