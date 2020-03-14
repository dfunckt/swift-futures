//
//  Cancellable.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol indicating that an activity or action may be canceled.
///
/// Calling `cancel()` frees up any allocated resources. It also stops side
/// effects such as timers, network access, or disk I/O.
public protocol Cancellable {
    /// Cancel the activity.
    func cancel()
}

extension Cancellable {
    @inlinable
    public func store(in set: inout Set<AnyCancellable>) {
        if let canceller = self as? AnyCancellable {
            set.insert(canceller)
        } else {
            set.insert(.init(self))
        }
    }

    @inlinable
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == AnyCancellable {
        if let canceller = self as? AnyCancellable {
            collection.append(canceller)
        } else {
            collection.append(.init(self))
        }
    }
}

/// A type-erasing cancellable object that executes a provided closure when
/// canceled or deallocated.
///
/// `AnyCancellable` is thread-safe; concurrent invocations to `cancel()` are
/// permitted and it is guaranteed that the closure is only ever invoked once.
/// There is no guarantee however on which thread the closure will be called.
public final class AnyCancellable: Cancellable {
    @usableFromInline var _cancelled: AtomicBool.RawValue = false
    @usableFromInline let _cancelFn: () -> Void

    /// Creates a type-erasing cancellable object to wrap the provided
    /// cancellable object.
    @inlinable
    public init<C: Cancellable>(_ canceller: C) {
        AtomicBool.initialize(&_cancelled, to: false)

        // We could be checking for `canceller as? AnyCancellable`
        // and taking ownership of its state here, but that would
        // create disjoint paths for cancellation -- cancellation
        // would be triggered as soon as *any* instance is deallocated.
        //
        // We'd rather provide ARC-like semantics which is easier
        // to reason about. As long as there are live AnyCancellable
        // instances referencing the same cancel function, the function
        // should *not* be invoked.
        _cancelFn = canceller.cancel
    }

    /// Initializes the cancellable object with the given cancel-time closure.
    @inlinable
    public init(_ fn: @escaping () -> Void) {
        AtomicBool.initialize(&_cancelled, to: false)
        _cancelFn = fn
    }

    @inlinable
    deinit {
        cancel()
    }

    @inlinable
    public func cancel() {
        guard !AtomicBool.exchange(&_cancelled, true) else {
            return
        }
        _cancelFn()
    }
}

extension AnyCancellable {
    public static var empty = AnyCancellable {}
}

extension AnyCancellable: Hashable {
    @inlinable
    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        return lhs === rhs
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
