//
//  Time.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Dispatch
import FuturesPlatform

@usableFromInline let MSEC_PER_SEC: Int64 = 1_000
@usableFromInline let USEC_PER_SEC: Int64 = 1_000_000
@usableFromInline let NSEC_PER_SEC: Int64 = 1_000_000_000
@usableFromInline let NSEC_PER_MSEC: Int64 = 1_000_000
@usableFromInline let NSEC_PER_USEC: Int64 = 1_000

@inlinable
func _clampedProduct<T: FixedWidthInteger>(_ a: T, _ b: T) -> T {
    let (result, overflow) = a.multipliedReportingOverflow(by: b)
    if overflow {
        return a > 0
            ? (b > 0 ? T.max : T.min)
            : (b < 0 ? T.max : T.min)
    }
    return result
}

@inlinable
func _clampedSum<T: FixedWidthInteger>(_ a: T, _ b: T) -> T {
    let (result, overflow) = a.addingReportingOverflow(b)
    if overflow {
        return a > 0 ? T.max : T.min
    }
    return result
}

@inlinable
func _gettime(_ clockid: clockid_t) -> timespec {
    var ts = timespec()
    let result = clock_gettime(clockid, &ts)
    assert(result == 0) // documented to only fail if `clockid` or `ts` are invalid
    return ts
}

// MARK: -

/// A value specifying the interval between two clock instants.
///
/// Duration can represent a range of ±292 years with nanosecond precision.
public struct Duration {
    @usableFromInline let _nanoseconds: Int64

    @inlinable
    public init(nanoseconds: Int64) {
        _nanoseconds = nanoseconds
    }
}

extension Duration {
    @inlinable
    public init(_ nanoseconds: UInt64) {
        self.init(nanoseconds: .init(clamping: nanoseconds))
    }

    @inlinable
    public init(_ nanoseconds: Int) {
        self.init(nanoseconds: .init(nanoseconds))
    }
}

extension Duration {
    /// - Parameter timespec: A `timespec` value describing the offset in
    ///     seconds and nanoseconds since the Unix Epoch (1970-01-01 00:00:00).
    @inlinable
    public init(_ timespec: timespec) {
        let nsec = _clampedProduct(Int64(timespec.tv_sec), NSEC_PER_SEC)
        self.init(nanoseconds: _clampedSum(nsec, Int64(timespec.tv_nsec)))
    }

    @inlinable
    public var timespec: timespec {
        let sec = Int(clamping: _nanoseconds / NSEC_PER_SEC)
        let nsec = Int(_nanoseconds % NSEC_PER_SEC)
        return .init(tv_sec: sec, tv_nsec: nsec)
    }
}

extension Duration {
    @inlinable
    public init(_ timeval: timeval) {
        let sec = _clampedProduct(Int64(timeval.tv_sec), NSEC_PER_SEC)
        let nsec = _clampedProduct(Int64(timeval.tv_usec), NSEC_PER_USEC)
        self.init(nanoseconds: _clampedSum(sec, nsec))
    }

    @inlinable
    public var timeval: timeval {
        let sec = Int(clamping: _nanoseconds / NSEC_PER_SEC)
        let usec = Int((_nanoseconds % NSEC_PER_SEC) / NSEC_PER_USEC)
        return .init(tv_sec: sec, tv_usec: .init(usec))
    }
}

extension Duration: CustomStringConvertible, CustomDebugStringConvertible {
    @inlinable
    public var description: String {
        return _nanoseconds.description
    }

    @inlinable
    public var debugDescription: String {
        return "\(Double(_nanoseconds) / Double(NSEC_PER_SEC))s"
    }
}

extension Duration: Strideable {
    public typealias Stride = Int64

    @inlinable
    public func distance(to other: Duration) -> Int64 {
        return .init(_nanoseconds.distance(to: other._nanoseconds))
    }

    @inlinable
    public func advanced(by n: Int64) -> Duration {
        return .init(nanoseconds: _nanoseconds.advanced(by: .init(clamping: n)))
    }
}

extension Duration: SignedNumeric {
    public typealias IntegerLiteralType = Int64
    public typealias Magnitude = UInt64

    @inlinable
    public init?<T>(exactly source: T) where T: BinaryInteger {
        guard let nanoseconds = Int64(exactly: source) else {
            return nil
        }
        _nanoseconds = nanoseconds
    }

    @inlinable
    public init(integerLiteral value: Int64) {
        _nanoseconds = value
    }

    /// The magnitude of this value.
    @inlinable
    public var magnitude: UInt64 {
        return _nanoseconds.magnitude
    }

    /// Returns -1 if this value is negative and 1 if it’s positive;
    /// otherwise, 0.
    @inlinable
    public func signum() -> Int64 {
        return _nanoseconds.signum()
    }

    @inlinable
    public func negated() -> Duration {
        return .init(nanoseconds: -_nanoseconds)
    }

    @inlinable
    public mutating func negate() {
        self = negated()
    }

    @inlinable
    public static func + (lhs: Duration, rhs: Duration) -> Duration {
        return .init(nanoseconds: _clampedSum(lhs._nanoseconds, rhs._nanoseconds))
    }

    @inlinable
    public static func - (lhs: Duration, rhs: Duration) -> Duration {
        return .init(nanoseconds: _clampedSum(lhs._nanoseconds, -rhs._nanoseconds))
    }

    @inlinable
    public static func * (lhs: Duration, rhs: Duration) -> Duration {
        return .init(nanoseconds: _clampedProduct(lhs._nanoseconds, rhs._nanoseconds))
    }

    @inlinable
    public static func += (lhs: inout Duration, rhs: Duration) {
        lhs = .init(nanoseconds: _clampedSum(lhs._nanoseconds, rhs._nanoseconds))
    }

    @inlinable
    public static func -= (lhs: inout Duration, rhs: Duration) {
        lhs = .init(nanoseconds: _clampedSum(lhs._nanoseconds, -rhs._nanoseconds))
    }

    @inlinable
    public static func *= (lhs: inout Duration, rhs: Duration) {
        lhs = .init(nanoseconds: _clampedProduct(lhs._nanoseconds, rhs._nanoseconds))
    }
}

extension Duration {
    /// The zero value.
    ///
    /// Zero is the identity element for addition. For any value,
    /// `x + .zero == x` and `.zero + x == x`.
    @inlinable
    public static var zero: Duration {
        return .init(nanoseconds: .zero)
    }

    /// The minimum representable duration.
    @inlinable
    public static var min: Duration {
        return .init(nanoseconds: .min)
    }

    /// The maximum representable duration.
    @inlinable
    public static var max: Duration {
        return .init(nanoseconds: .max)
    }

    @inlinable
    public static func nanoseconds(_ nsec: Int) -> Duration {
        return .init(nsec)
    }

    @inlinable
    public static func microseconds(_ usec: Int) -> Duration {
        let nsec = _clampedProduct(Int64(usec), NSEC_PER_USEC)
        return .init(nanoseconds: nsec)
    }

    @inlinable
    public static func milliseconds(_ msec: Int) -> Duration {
        let nsec = _clampedProduct(Int64(msec), NSEC_PER_MSEC)
        return .init(nanoseconds: nsec)
    }

    @inlinable
    public static func seconds(_ sec: Int) -> Duration {
        let nsec = _clampedProduct(Int64(sec), NSEC_PER_SEC)
        return .init(nanoseconds: nsec)
    }

    @inlinable
    public static func seconds(_ sec: Double) -> Duration {
        let seconds = Int64(sec) // rounds toward zero
        let nsec1 = _clampedProduct(seconds, NSEC_PER_SEC)
        let nsec2 = Int64((sec - Double(seconds)) * Double(NSEC_PER_SEC))
        return .init(nanoseconds: _clampedSum(nsec1, nsec2))
    }
}

// MARK: -

public protocol ClockProtocol {
    /// Returns the offset since the clock's reference date.
    ///
    /// The reference date can be arbitrary with respect to wall clock time,
    /// but an offset value of `0` must always refer to that reference date.
    static func offsetFromReferenceDate() -> Duration
}

/// A protocol that defines clocks that increment monotonically.
///
/// For monotonic clocks, the following condition always holds:
///
///     Clock.offsetFromReferenceDate() <= Clock.offsetFromReferenceDate()
///
public protocol MonotonicClock: ClockProtocol {}

// MARK: -

public enum SystemClock {
    /// A system clock that increments monotonically, tracking the time since
    /// an arbitrary point.
    ///
    /// On Darwin, this uses `mach_absolute_time`, which provides nanosecond
    /// accuracy and does not increment while the system is asleep.
    ///
    /// On Linux, this uses `clock_gettime()` with `CLOCK_MONOTONIC`, which
    /// typically provides microsecond accuracy and keeps incrementing while
    /// the system is asleep.
    public enum Monotonic: MonotonicClock {
        @inlinable
        public static func offsetFromReferenceDate() -> Duration {
            #if canImport(Darwin)
            return .init(clock_gettime_nsec_np(CLOCK_UPTIME_RAW))
            #else
            return .init(_gettime(CLOCK_MONOTONIC))
            #endif
        }
    }

    /// A system clock tracking wall clock time elapsed since the Epoch with
    /// millisecond accuracy.
    ///
    /// This is the same clock as the one used by `gettimeofday(2)`.
    public enum Realtime: ClockProtocol {
        @inlinable
        public static func offsetFromReferenceDate() -> Duration {
            return .init(_gettime(CLOCK_REALTIME))
        }
    }
}

// MARK: -

/// A value specifying a point relative to a clock's time reference.
public struct Instant<Clock: ClockProtocol>: Strideable {
    public typealias Stride = Duration

    /// Returns the instant representing the current offset since the clock's
    /// reference date.
    @inlinable
    public static func now() -> Instant<Clock> {
        return .init(offset: Clock.offsetFromReferenceDate())
    }

    @usableFromInline let _offset: Duration

    @inlinable
    init(offset: Duration) {
        _offset = offset
    }

    @inlinable
    public init(_ instant: Instant) {
        _offset = instant._offset
    }

    @inlinable
    public init<C: ClockProtocol>(_ instant: Instant<C>) {
        let clockOffset = Clock.offsetFromReferenceDate() - C.offsetFromReferenceDate()
        _offset = instant._offset + clockOffset
    }

    @inlinable
    public func elapsedDuration() -> Duration {
        return Clock.offsetFromReferenceDate() - _offset
    }

    @inlinable
    public var hasElapsed: Bool {
        return Clock.offsetFromReferenceDate() > _offset
    }

    @inlinable
    public func distance(to other: Self) -> Duration {
        return other._offset - _offset
    }

    @inlinable
    public func advanced(by n: Duration) -> Self {
        return .init(offset: _offset + n)
    }
}

extension Instant: CustomDebugStringConvertible {
    @inlinable
    public var debugDescription: String {
        return "Instant<\(Clock.self)>(\(_offset.debugDescription))"
    }
}

extension Instant {
    @inlinable
    public static func - (lhs: Instant, rhs: Instant) -> Duration {
        return lhs._offset - rhs._offset
    }

    @inlinable
    public static func - (lhs: Instant, rhs: Double) -> Instant {
        return .init(offset: lhs._offset - .seconds(rhs))
    }

    @inlinable
    public static func + (lhs: Instant, rhs: Double) -> Instant {
        return .init(offset: lhs._offset + .seconds(rhs))
    }

    @inlinable
    public static func += (lhs: inout Instant, rhs: Double) {
        lhs = .init(offset: lhs._offset + .seconds(rhs))
    }

    @inlinable
    public static func -= (lhs: inout Instant, rhs: Double) {
        lhs = .init(offset: lhs._offset - .seconds(rhs))
    }

    @inlinable
    public static func - (lhs: Instant, rhs: Duration) -> Instant {
        return .init(offset: lhs._offset - rhs)
    }

    @inlinable
    public static func + (lhs: Instant, rhs: Duration) -> Instant {
        return .init(offset: lhs._offset + rhs)
    }

    @inlinable
    public static func += (lhs: inout Instant, rhs: Duration) {
        lhs = .init(offset: lhs._offset + rhs)
    }

    @inlinable
    public static func -= (lhs: inout Instant, rhs: Duration) {
        lhs = .init(offset: lhs._offset - rhs)
    }
}

extension Instant where Clock == SystemClock.Monotonic {
    @inlinable
    public init(_ uptime: DispatchTime) {
        if uptime == .distantFuture {
            _offset = .max
        } else {
            _offset = .init(uptime.uptimeNanoseconds)
        }
    }
}

extension Instant where Clock == SystemClock.Realtime {
    @inlinable
    public init(_ wallTime: DispatchWallTime) {
        if wallTime == .distantFuture {
            _offset = .max
        } else {
            _offset = .init(UInt64(-Int64(bitPattern: wallTime.rawValue)))
        }
    }
}

extension DispatchTime {
    @inlinable
    public init(_ instant: Instant<SystemClock.Monotonic>) {
        if instant._offset == .max {
            self = .distantFuture
        } else {
            self.init(uptimeNanoseconds: instant._offset.magnitude)
        }
    }
}

extension DispatchWallTime {
    @inlinable
    public init(_ instant: Instant<SystemClock.Realtime>) {
        if instant._offset == .max {
            self = .distantFuture
        } else {
            self.init(timespec: instant._offset.timespec)
        }
    }
}

extension DispatchQueue {
    @inlinable
    public func async(after deadline: Instant<SystemClock.Monotonic>, execute block: @escaping () -> Void) {
        asyncAfter(deadline: DispatchTime(deadline), execute: block)
    }

    @inlinable
    public func async(after deadline: Instant<SystemClock.Realtime>, execute block: @escaping () -> Void) {
        asyncAfter(wallDeadline: DispatchWallTime(deadline), execute: block)
    }
}

extension DispatchSemaphore {
    @inlinable
    public func wait(timeout: Instant<SystemClock.Monotonic>) -> DispatchTimeoutResult {
        return wait(timeout: DispatchTime(timeout))
    }

    @inlinable
    public func wait(timeout: Instant<SystemClock.Realtime>) -> DispatchTimeoutResult {
        return wait(wallTimeout: DispatchWallTime(timeout))
    }
}
