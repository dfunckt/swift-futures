//
//  AtomicBuffer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

@usableFromInline
struct _AtomicBufferHead {
    @usableFromInline let capacity: UInt
    @usableFromInline var head: AtomicUInt.RawValue = 0 // producers
    @usableFromInline var tail: AtomicUInt.RawValue = 0 // consumers

    @inlinable
    init(capacity: UInt) {
        self.capacity = capacity
    }
}

@usableFromInline
struct _AtomicBufferSlot<T> {
    @usableFromInline var sequence: AtomicUInt.RawValue = 0
    @usableFromInline var element: T?

    @inlinable
    init(_ sequence: AtomicUInt.RawValue) {
        AtomicUInt.initialize(&self.sequence, to: sequence)
    }
}

// This is an implementation of "bounded MPMC queue" from 1024cores.net.
@usableFromInline
final class _AtomicBuffer<T>: ManagedBuffer<_AtomicBufferHead, _AtomicBufferSlot<T>> {
    @inlinable
    static func create(capacity: Int) -> _AtomicBuffer {
        let capacity = Int(UInt32(capacity))
        let buffer = create(minimumCapacity: capacity) { _ in
            .init(capacity: UInt(capacity))
        }
        buffer.withUnsafeMutablePointerToElements {
            for i in 0..<capacity {
                $0.advanced(by: i).initialize(to: .init(UInt(i)))
            }
        }
        return unsafeDowncast(buffer, to: _AtomicBuffer.self)
    }

    @inlinable
    deinit {
        withUnsafeMutablePointers {
            $1.deinitialize(count: Int($0.pointee.capacity))
            $0.deinitialize(count: 1)
        }
    }
}

extension _AtomicBuffer {
    @usableFromInline
    @_transparent
    var _capacity: Int {
        withUnsafeMutablePointerToHeader {
            Int(bitPattern: $0.pointee.capacity)
        }
    }

    @usableFromInline
    @_transparent
    func _tryPush(_ element: T) -> Bool {
        return withUnsafeMutablePointers { header, buffer in
            let head = AtomicUInt.load(&header.pointee.head, order: .relaxed)
            let index = Int(bitPattern: head % header.pointee.capacity)
            let next = AtomicUInt.load(&buffer[index].sequence, order: .acquire)
            if head > next {
                return false // full
            }
            assert(head == next, "concurrent push on single-producer queue")
            AtomicUInt.store(&header.pointee.head, head &+ 1, order: .relaxed)
            assert(buffer[index].element == nil, "expected nil at index \(index), found item")
            buffer[index].element = element
            AtomicUInt.store(&buffer[index].sequence, head &+ 1, order: .release)
            return true
        }
    }

    @usableFromInline
    @_transparent
    func _tryPushConcurrent(_ element: T) -> Bool {
        return withUnsafeMutablePointers { header, buffer in
            var backoff = Backoff()
            while true {
                let head = AtomicUInt.load(&header.pointee.head, order: .relaxed)
                let index = Int(bitPattern: head % header.pointee.capacity)
                let next = AtomicUInt.load(&buffer[index].sequence, order: .acquire)
                if head > next {
                    return false // full
                }
                if head == next,
                   head == AtomicUInt.compareExchange(&header.pointee.head, head, head &+ 1, order: .relaxed) {
                    assert(buffer[index].element == nil, "expected nil at index \(index), found item")
                    buffer[index].element = element
                    AtomicUInt.store(&buffer[index].sequence, head &+ 1, order: .release)
                    return true
                }
                // FIXME: return if we exhausted our budget
                backoff.snooze()
            }
        }
    }

    @usableFromInline
    @_transparent
    func _pop() -> T? {
        return withUnsafeMutablePointers { header, buffer in
            let tail = AtomicUInt.load(&header.pointee.tail, order: .relaxed)
            let index = Int(bitPattern: tail % header.pointee.capacity)
            let next = AtomicUInt.load(&buffer[index].sequence, order: .acquire)
            if tail &+ 1 > next {
                return nil // empty
            }
            assert(tail + 1 == next, "concurrent pop on single-consumer queue")
            AtomicUInt.store(&header.pointee.tail, tail &+ 1, order: .relaxed)
            let item = buffer[index].element
            assert(item != nil, "expected item at index \(index), found nil")
            buffer[index].element = nil
            AtomicUInt.store(&buffer[index].sequence, tail &+ header.pointee.capacity, order: .release)
            return item
        }
    }

    @usableFromInline
    @_transparent
    func _popConcurrent() -> T? {
        return withUnsafeMutablePointers { header, buffer in
            var backoff = Backoff()
            while true {
                let tail = AtomicUInt.load(&header.pointee.tail, order: .relaxed)
                let index = Int(bitPattern: tail % header.pointee.capacity)
                let next = AtomicUInt.load(&buffer[index].sequence, order: .acquire)
                if tail &+ 1 > next {
                    return nil // empty
                }
                if tail &+ 1 == next,
                   tail == AtomicUInt.compareExchange(&header.pointee.tail, tail, tail &+ 1, order: .relaxed) {
                    let item = buffer[index].element
                    assert(item != nil, "expected item at index \(index), found nil")
                    buffer[index].element = nil
                    AtomicUInt.store(&buffer[index].sequence, tail &+ header.pointee.capacity, order: .release)
                    return item
                }
                // FIXME: return if we exhausted our budget
                backoff.snooze()
            }
        }
    }
}
