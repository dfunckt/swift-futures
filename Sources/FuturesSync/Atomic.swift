//
//  Atomic.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

@_exported import enum FuturesPrivate.AtomicLoadMemoryOrder
@_exported import enum FuturesPrivate.AtomicMemoryOrder
@_exported import enum FuturesPrivate.AtomicStoreMemoryOrder

public enum Atomic {}

extension Atomic {
    /// Generic memory order-dependent fence synchronization primitive.
    ///
    /// Establishes memory synchronization ordering of non-atomic and relaxed
    /// atomic accesses, as instructed by `order`, without an associated
    /// atomic operation.
    ///
    /// For example, all non-atomic and relaxed atomic stores that happen
    /// before a memory_order_release fence in thread A will be synchronized
    /// with non-atomic and relaxed atomic loads from the same locations made
    /// in thread B after an memory_order_acquire fence.
    ///
    /// - Parameters:
    ///     - order: the memory ordering executed by this fence
    @_transparent
    public static func threadFence(order: AtomicMemoryOrder = .seqcst) {
        CAtomicThreadFence(order)
    }

    /// Indicates to the hardware that the current thread is performing a task,
    /// for example a spinlock, that can be swapped out. Hardware can use this
    /// hint to suspend and resume threads.
    @_transparent
    public static func hardwarePause() {
        CAtomicHardwarePause()
    }

    /// Causes the calling thread to relinquish the CPU. The thread is moved
    /// to the end of the queue for its static priority and a new thread gets
    /// to run.
    ///
    /// - Parameters:
    ///     - timeout: The time interval to suppress this thread's priority
    ///         for, in milliseconds.
    @_transparent
    public static func preemptionYield(_ timeout: UInt64) {
        CAtomicPreemptionYield(timeout)
    }
}

// MARK: - Private -

public protocol _CAtomicValue {
    associatedtype AtomicRawValue
    associatedtype AtomicPointer
}

public protocol _CAtomicInteger: _CAtomicValue
    where AtomicRawValue: FixedWidthInteger {}
