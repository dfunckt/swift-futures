//
//  PosixConditionLock.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)
import Darwin.POSIX.pthread
#else
import Glibc
#endif

/// A condition variable whose semantics follow those used for POSIX-style
/// conditions.
///
/// A condition object acts as both a lock and a checkpoint in a given thread.
/// The lock protects your code while it tests the condition and performs the
/// task triggered by the condition. The checkpoint behavior requires that the
/// condition be true before the thread proceeds with its task. While the
/// condition is not true, the thread blocks. It remains blocked until another
/// thread signals the condition object.
///
/// The semantics for using a PosixConditionLock object are as follows:
///
/// - Lock the condition object.
/// - Test a boolean predicate. (This predicate is a boolean flag or other
///   variable in your code that indicates whether it is safe to perform the
///   task protected by the condition.)
/// - If the boolean predicate is false, call the condition object’s `wait()`
///   or `wait(until:)` method to block the thread. Upon returning from these
///   methods, go to step 2 to retest your boolean predicate. (Continue
///   waiting and retesting the predicate until it is true.)
/// - If the boolean predicate is true, perform the task.
/// - Optionally update any predicates (or signal any conditions) affected by
///   your task.
/// - When your task is done, unlock the condition object.
///
/// The pseudocode for performing the preceding steps would therefore look
/// something like the following:
///
///     lock the condition
///     while (!(boolean_predicate)) {
///         wait on condition
///     }
///     do protected work
///     (optionally, signal or broadcast the condition again or change a predicate value)
///     unlock the condition
///
/// Whenever you use a condition object, the first step is to lock the
/// condition. Locking the condition ensures that your predicate and task code
/// are protected from interference by other threads using the same condition.
/// Once you have completed your task, you can set other predicates or signal
/// other conditions based on the needs of your code. You should always set
/// predicates and signal conditions while holding the condition object’s lock.
///
/// When a thread waits on a condition, the condition object unlocks its lock
/// and blocks the thread. When the condition is signaled, the system wakes up
/// the thread. The condition object then reacquires its lock before returning
/// from the `wait()` or `wait(until:)` method. Thus, from the point of view
/// of the thread, it is as if it always held the lock.
///
/// A boolean predicate is an important part of the semantics of using
/// conditions because of the way signaling works. Signaling a condition does
/// not guarantee that the condition itself is true. There are timing issues
/// involved in signaling that may cause false signals to appear. Using a
/// predicate ensures that these spurious signals do not cause you to perform
/// work before it is safe to do so. The predicate itself is simply a flag or
/// other variable in your code that you test in order to acquire a Bool
/// result.
///
/// Backed by `pthread_mutex` and `pthread_cond`.
public final class PosixConditionLock {
    @usableFromInline var _cond = pthread_cond_t()
    @usableFromInline var _mutex = pthread_mutex_t()

    @inlinable
    public init() {
        var rc: CInt
        var attr = normalMutexAttributes
        rc = pthread_mutex_init(&_mutex, &attr)
        precondition(rc == 0)
        rc = pthread_cond_init(&_cond, nil)
        precondition(rc == 0)
    }

    @inlinable
    deinit {
        var rc: CInt
        rc = pthread_mutex_destroy(&_mutex)
        precondition(rc == 0)
        rc = pthread_cond_destroy(&_cond)
        precondition(rc == 0)
    }

    /// Signals the condition, waking up one thread waiting on it.
    ///
    /// You use this method to wake up one thread that is waiting on the
    /// condition. You may call this method multiple times to wake up multiple
    /// threads. If no threads are waiting on the condition, this method does
    /// nothing.
    ///
    /// To avoid race conditions, you should invoke this method only while the
    /// condition is locked.
    @inlinable
    public func signal() {
        let rc = pthread_cond_signal(&_cond)
        precondition(rc == 0)
    }

    /// Signals the condition, waking up all threads waiting on it.
    ///
    /// If no threads are waiting on the condition, this method does nothing.
    ///
    /// To avoid race conditions, you should invoke this method only while the
    /// condition is locked.
    @inlinable
    public func broadcast() {
        let rc = pthread_cond_broadcast(&_cond)
        precondition(rc == 0)
    }

    /// Blocks the current thread until the condition is signaled.
    ///
    /// You must lock the condition prior to calling this method.
    @inlinable
    public func wait() {
        let rc = pthread_cond_wait(&_cond, &_mutex)
        precondition(rc == 0)
    }

    /// Blocks the current thread until the condition is signaled or the
    /// specified time limit is reached.
    ///
    /// Values for `deadline` can be obtained by adding the required time
    /// interval to the current time obtained using `gettimeofday(2)`.
    ///
    ///     // Get the current system time
    ///     var tv: timeval
    ///     let rc = gettimeofday(&tv, nil)
    ///     assert(rc == 0)
    ///
    ///     // Specify the desired time interval
    ///     let timeout = (sec: 0, nsec: 0)
    ///
    ///     // Construct the `timespec` value
    ///     let ts = timespec(
    ///         tv_sec: tv.tv_sec + timeout.sec,
    ///         tv_nsec: tv.tv_usec * 1_000 + timeout.nsec
    ///     )
    ///
    /// You must lock the condition prior to calling this method.
    ///
    /// - Parameter deadline: The absolute time, in seconds and nanoseconds
    ///     since the Unix Epoch, at which to wake up the thread if the
    ///     condition has not been signaled.
    /// - Returns: `true` if the condition was signaled; otherwise, `false` if
    ///     the time limit was reached.
    @inlinable
    public func wait(until deadline: timespec) -> Bool {
        var deadline = deadline
        let rc = pthread_cond_timedwait(&_cond, &_mutex, &deadline)
        precondition(rc != EINVAL)
        return rc != ETIMEDOUT
    }
}

extension PosixConditionLock: LockingProtocol {
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
