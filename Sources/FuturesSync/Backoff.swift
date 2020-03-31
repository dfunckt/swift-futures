//
//  Backoff.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

// Ported over from crossbeam: https://github.com/crossbeam-rs/crossbeam

@usableFromInline let _MAX_SPINS: UInt64 = 6 // 2^6 = 64
@usableFromInline let _MAX_YIELDS: UInt64 = 10 // 2^10 = 1024

/// Helper for implementing spin loops.
///
/// An example of a busy-wait loop. The current thread will efficiently spin,
/// yielding control at appropriate times, until `ready` becomes `true`.
///
///     func waitUntil(_ ready: AtomicBool) {
///         var backoff = Backoff()
///         while !ready.load() {
///             backoff.snooze()
///         }
///     }
///
///     let ready = AtomicBool(false)
///     DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
///         ready.store(true)
///     }
///
///     assert(ready.load() == false)
///     waitUntil(ready)
///     assert(ready.load() == true)
///
/// An example of retrying an operation until it succeeds.
///
///     extension AtomicInt {
///         func fetchMul(by b: Int) -> Int {
///             var backoff = Backoff()
///             while true {
///                 let value = self.load()
///                 if self.compareExchangeWeak(value, value * b) == value {
///                     return value
///                 }
///                 backoff.snooze()
///             }
///         }
///     }
///
///     let a = AtomicInt(6)
///     assert(a.fetchMul(by: 7) == 6)
///     assert(a.load() == 42)
///
public struct Backoff {
    // UInt64 so it's compatible with `preemptionYield()`
    @usableFromInline var _step: UInt64 = 0

    @inlinable
    public init() {}

    /// A boolean denoting whether backoff completed and it is no longer
    /// useful to spin, indicating contention.
    ///
    /// If `isComplete` is `true`, the caller should arrange for getting
    /// notified when the condition the loop waits on is satisfied and park
    /// the current thread.
    @inlinable
    public var isComplete: Bool {
        _step > _MAX_YIELDS
    }

    @inlinable
    public mutating func snooze() {
        if _step <= _MAX_SPINS {
            for _ in 0..<(1 << _step) {
                Atomic.hardwarePause()
            }
        } else {
            Atomic.preemptionYield(_step)
        }
        if _step <= _MAX_YIELDS {
            _step += 1
        }
    }
}
