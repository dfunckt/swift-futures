//
//  SharedScheduler.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A scheduler that can accept new tasks from any thread (see `trySubmit(_:)`).
/// Scheduled tasks can be consumed from a single thread (see `next()`).
///
/// This is the default scheduler used by most built-in executors.
public final class SharedScheduler<Output, Waker: WakerProtocol> {
    public typealias Task = ScheduledTask<SharedScheduler>
    public typealias Future = (inout Context) -> Poll<Output>

    /// A FIFO queue of tasks that are ready to be polled.
    @usableFromInline let _ready = TaskQueue<SharedScheduler>()

    /// A lock protecting `_cache` and `_count` from concurrent access.
    @usableFromInline let _lock = UnfairLock()

    /// A subset of bound tasks that are already contained in the task list
    /// and can be reused.
    ///
    /// Must only be accessed with _lock held.
    @usableFromInline var _cache = [Task]()

    /// The number of bound tasks. Maintained separately because the task
    /// list contains both active and reusable tasks, so `_tasks.count` is
    /// not accurate.
    ///
    /// Must only be accessed with _lock held.
    @usableFromInline var _count = 0

    /// A list of all tasks that are bound to this scheduler.
    @usableFromInline var _tasks = TaskList<SharedScheduler>()

    /// The waker to signal when new tasks become ready to be polled.
    @usableFromInline let _waker: Waker

    @inlinable
    public init(waker: Waker) {
        _waker = waker
    }

    @inlinable
    public var waker: Waker {
        _waker
    }

    @inlinable
    public func destroy() {
        // Cache contains a subset of tasks that are already contained
        // in the task list, so they will be destroyed with it. We just
        // need to empty it here to clear references.
        _lock.sync { _cache = [] }

        // The task list links together all tasks that are bound
        // to this scheduler. Iterate over the list and cancel them
        // in order to clear their reference to us.
        for task in _tasks.moveElements() {
            task.destroy()
        }

        // The ready queue may contain tasks that haven't yet been
        // bound to us, so they wouldn't have been destroyed above
        // as they're not reachable by the active list.
        while let task = _ready.dequeue() {
            task.destroy()
        }
    }
}

extension SharedScheduler: SchedulerProtocol {
    public typealias Failure = Never

    /// Wraps the given future in a Task, potentially reusing a previously
    /// released one from a cache.
    @inlinable
    func _makeTask(_ future: @escaping Future) -> Task {
        // May be called from any thread.
        let task: Task? = _lock.sync {
            if _cache.count > 0 {
                // Tasks in cache are already bound to the scheduler so
                // there won't be another `bind(_:)` call to increment the
                // counter, so must we do that manually here.
                _count += 1
                return _cache.removeLast()
            }
            return nil
        }
        if let task = task {
            task.prepareForReuse(future: future)
            return task
        }
        return .allocate(future: future)
    }

    @inlinable
    public func trySubmit(_ future: @escaping Future) -> Result<Void, Failure> {
        // May be called from any thread.
        let task = _makeTask(future)
        _ready.enqueue(task)
        return .success(())
    }

    @inlinable
    public var count: Int {
        // May be called from any thread.
        _lock.sync { _count }
    }

    @inlinable
    public func next() -> Task? {
        // Only called from the thread that owns the scheduler.
        _ready.dequeue()
    }

    @inlinable
    public func bind(_ task: Task) {
        // Only called by the Task during `poll()`,
        // therefore from the thread that owns the scheduler.
        _tasks.append(task)
        _lock.sync { _count += 1 }
    }

    @inlinable
    public func release(_ task: Task, from _: SharedScheduler) {
        // Only called by the Task during `poll()`,
        // therefore from the thread that owns the scheduler.
        task.release()
        _lock.sync {
            _count -= 1
            assert(_count >= 0)
            _cache.append(task)
        }
    }

    @inlinable
    public func schedule(_ task: Task, from _: SharedScheduler) {
        // Only called by the Task during `poll()`,
        // therefore from the thread that owns the scheduler.
        _ready.enqueue(task)
    }

    @inlinable
    public func didReceiveSignal(_ task: Task) {
        // May be called from any thread.
        _ready.enqueue(task)
        _waker.signal()
    }
}

extension SharedScheduler: CustomDebugStringConvertible {
    public var debugDescription: String {
        let count = _lock.sync { _count }
        let ready = !_ready.isEmpty
        return "SharedScheduler<\(Output.self)>(ready: \(ready), active: \(count), waker: \(String(reflecting: _waker)))"
    }
}
