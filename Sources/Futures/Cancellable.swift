//
//  Cancellable.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol indicating that an activity or action supports cancellation.
///
/// Calling `cancel()` frees up any allocated resources. It also stops side
/// effects such as timers, network access, or disk I/O.
public protocol Cancellable {
    /// Cancel the activity or action.
    func cancel()
}

extension Cancellable {
    /// Stores this cancellable instance in the specified set.
    @inlinable
    public func store(in set: inout Set<AnyCancellable>) {
        if let canceller = self as? AnyCancellable {
            set.insert(canceller)
        } else {
            set.insert(.init(self))
        }
    }

    /// Stores this cancellable instance in the specified collection.
    @inlinable
    public func store<C: RangeReplaceableCollection>(in collection: inout C) where C.Element == AnyCancellable {
        if let canceller = self as? AnyCancellable {
            collection.append(canceller)
        } else {
            collection.append(.init(self))
        }
    }
}

/// A type-erasing cancellable value that executes a provided closure when
/// canceled.
///
/// `AnyCancellable` maintains a reference to the closure and the closure is
/// invoked automatically when it is no longer referenced by any instance.
/// It is guaranteed the closure will be invoked at most once.
///
/// `AnyCancellable` is thread-safe; concurrent invocations to `cancel()` are
/// permitted and it is guaranteed that the closure is only ever invoked once.
/// There is no guarantee however on which thread the closure will be called.
public struct AnyCancellable: Cancellable {
    @usableFromInline final class _Box {
        @usableFromInline var _cancelled: AtomicBool.RawValue = false
        @usableFromInline let _cancelFn: () -> Void

        @inlinable
        init(_fn: @escaping () -> Void) {
            AtomicBool.initialize(&_cancelled, to: false)
            _cancelFn = _fn
        }

        @inlinable
        deinit {
            cancel()
        }

        @inlinable
        func cancel() {
            guard !AtomicBool.exchange(&_cancelled, true) else {
                return
            }
            _cancelFn()
        }
    }

    @usableFromInline let _box: _Box

    /// Creates a type-erasing cancellable object to wrap the provided
    /// cancellable object.
    @inlinable
    public init(_ canceller: Cancellable) {
        if let canceller = canceller as? AnyCancellable {
            _box = canceller._box
        } else {
            _box = .init(_fn: canceller.cancel)
        }
    }

    /// Creates a type-erasing cancellable object to wrap the provided
    /// cancellable object.
    @inlinable
    public init(_ canceller: AnyCancellable) {
        _box = canceller._box
    }

    /// Initializes the cancellable object with the given cancel-time closure.
    @inlinable
    public init(_ fn: @escaping () -> Void) {
        _box = .init(_fn: fn)
    }

    @inlinable
    public func cancel() {
        _box.cancel()
    }
}

extension AnyCancellable {
    public static var empty = AnyCancellable {}
}

extension AnyCancellable: Hashable {
    @inlinable
    public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
        return lhs._box === rhs._box
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(_box))
    }
}
