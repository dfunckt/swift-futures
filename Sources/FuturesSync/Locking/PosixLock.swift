//
//  PosixLock.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)
import Darwin.POSIX.pthread
#else
import Glibc
#endif

private func _makeMutexAttributes(type: Int32) -> pthread_mutexattr_t {
    var rc: Int32
    var attr = pthread_mutexattr_t()
    rc = pthread_mutexattr_init(&attr)
    precondition(rc == 0)
    rc = pthread_mutexattr_settype(&attr, type)
    precondition(rc == 0)
    return attr
}

@usableFromInline let _normalMutexAttributes = _makeMutexAttributes(
    type: Int32(PTHREAD_MUTEX_ERRORCHECK)
)

@usableFromInline let _recursiveMutexAttributes = _makeMutexAttributes(
    type: Int32(PTHREAD_MUTEX_RECURSIVE)
)

/// A mutually exclusive (or mutex) lock.
///
/// A mutex is a type of semaphore that grants access to only one thread at a
/// time. If a mutex is in use and another thread tries to acquire it, that
/// thread blocks until the mutex is released by its original holder. If
/// multiple threads compete for the same mutex, only one at a time is allowed
/// access to it.
///
/// You instantiate a re-entrant variant by passing `true` to `init(recursive:)`.
/// A recursive lock may be acquired multiple times by the same thread without
/// causing a deadlock, a situation where a thread is permanently blocked waiting
/// for itself to relinquish a lock. While the locking thread has one or more
/// locks, all other threads are prevented from accessing the code protected by
/// the lock.
///
/// Both types of locks check for usage errors. See `PTHREAD_MUTEX_ERRORCHECK`
/// and `PTHREAD_MUTEX_RECURSIVE` in `man 3 pthread_mutexattr_settype`.
///
/// Backed by `pthread_mutex`.
public final class PosixLock: LockingProtocol {
    @usableFromInline var _mutex = pthread_mutex_t()

    @inlinable
    public init(recursive: Bool = false) {
        var attr = recursive
            ? _recursiveMutexAttributes
            : _normalMutexAttributes
        let rc = pthread_mutex_init(&_mutex, &attr)
        precondition(rc == 0)
    }

    @inlinable
    deinit {
        let rc = pthread_mutex_destroy(&_mutex)
        precondition(rc == 0)
    }

    @inlinable
    public func tryAcquire() -> Bool {
        return pthread_mutex_trylock(&_mutex) == 0
    }

    @inlinable
    public func acquire() {
        let rc = pthread_mutex_lock(&_mutex)
        precondition(rc == 0)
    }

    @inlinable
    public func release() {
        let rc = pthread_mutex_unlock(&_mutex)
        precondition(rc == 0)
    }
}
