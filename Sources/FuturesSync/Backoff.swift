//
//  Backoff.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

/// Helper for implementing spin loops.
///
/// An example of a busy-wait loop. The current thread will efficiently spin,
/// yielding control at appropriate times, until `ready` becomes `true`.
///
///     func waitUntil(_ ready: AtomicBool) {
///         var backoff = Backoff()
///         while !ready.load() {
///             backoff.yield()
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
///     func fetchMul(_ a: AtomicInt, by b: Int) -> Int {
///         var backoff = Backoff()
///         while true {
///             let value = a.load()
///             if a.compareExchangeWeak(value, value * b) == value {
///                 return value
///             }
///             backoff.spin()
///         }
///     }
///
///     let a = AtomicInt(6)
///     assert(fetchMul(a, by: 7) == 6)
///     assert(a.load() == 42)
///
public struct Backoff {
    @usableFromInline static let MAX_SPINS: UInt64 = 6 // 2^6 = 64
    @usableFromInline static let MAX_YIELD: UInt64 = 10 // 2^10 = 1024

    @usableFromInline var _step: UInt64 = 0

    @inlinable
    public init() {}

    @inlinable
    public mutating func reset() {
        _step = 0
    }

    /// - Returns: `true` if backoff completed and it is no longer useful to
    ///     loop, indicating contention.
    @inlinable
    public mutating func spin() -> Bool {
        var spins = 1 << min(_step, Backoff.MAX_SPINS)
        while spins > 0 {
            Atomic.hardwarePause()
            spins -= 1
        }
        if _step <= Backoff.MAX_SPINS {
            _step += 1
            return false
        } else {
            // FIXME: report contention
            return true
        }
    }

    /// - Returns: `true` if backoff completed and it is no longer useful to
    ///     loop, indicating contention.
    @inlinable
    public mutating func yield() -> Bool {
        if _step < Backoff.MAX_SPINS {
            var spins = 1 << _step
            while spins > 0 {
                Atomic.hardwarePause()
                spins -= 1
            }
        } else {
            Atomic.preemptionYield(_step)
        }
        if _step < Backoff.MAX_YIELD {
            _step += 1
            return false
        } else {
            // FIXME: report contention
            return true
        }
    }
}
