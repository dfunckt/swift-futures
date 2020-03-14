//
//  LocalScheduler.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A minimal scheduler that can only be used from a single thread.
///
/// For an example of using this scheduler, see the source code for
/// `JoinAllFuture`.
public final class LocalScheduler<Output, Waker: WakerProtocol> {
    public typealias Task = ScheduledTask<LocalScheduler>
    public typealias Future = (inout Context) -> Poll<Output>

    @usableFromInline
    struct State: AtomicBitset, CustomDebugStringConvertible {
        @usableFromInline typealias RawValue = AtomicUInt.RawValue
        @usableFromInline var rawValue: RawValue

        @inlinable
        @_transparent
        init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }

    @usableFromInline let _waker: Waker
    @usableFromInline var _state: State.RawValue = 0

    @usableFromInline var _ready = TaskQueue<LocalScheduler>()
    @usableFromInline var _active = TaskList<LocalScheduler>()
    @usableFromInline var _cache = AdaptiveQueue<Task>()

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
        retry: while true {
            switch State.compareExchange(&_state, .open, .closed, order: .acqrel, loadOrder: .acquire) {
            case .closed:
                // Already closed
                return
            case .open:
                // We're now guaranteed no more tasks will be enqueued
                break retry
            default:
                // A thread is into `didReceiveSignal(_:)`
                Atomic.hardwarePause()
                continue retry
            }
        }

        _cache.clear()

        for task in _active.moveElements() {
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

extension LocalScheduler.State {
    @inlinable static var open: Self {
        @_transparent get { 0b00 }
    }

    @inlinable static var closed: Self {
        @_transparent get { .init(rawValue: ~(RawValue.max &>> 1)) }
    }

    @inlinable var isClosed: Bool {
        @_transparent get { contains(.closed) }
    }
}

extension LocalScheduler: SchedulerProtocol {
    public typealias Failure = Never

    @inlinable
    public func trySubmit(_ future: @escaping Future) -> Result<Void, Failure> {
        assert(
            !State.load(&_state, order: .relaxed).isClosed,
            "cannot enqueue after shutdown"
        )
        let task: Task
        if let t = _cache.pop() {
            t.prepareForReuse(future: future)
            task = t
        } else {
            task = Task.allocate(future: future)
        }
        _ready.enqueue(task)
        return .success(())
    }

    @inlinable
    public var count: Int {
        _active.count - _cache.count
    }

    @inlinable
    public func next() -> Task? {
        assert(
            !State.load(&_state, order: .relaxed).isClosed,
            "cannot dequeue after shutdown"
        )
        return _ready.dequeue()
    }

    @inlinable
    public func bind(_ task: Task) {
        _active.append(task)
    }

    @inlinable
    public func release(_ task: Task, from scheduler: LocalScheduler) {
        assert(scheduler === self, "LocalScheduler does not support task sharing")
        task.release()
        _cache.push(task)
    }

    @inlinable
    public func schedule(_ task: Task, from scheduler: LocalScheduler) {
        assert(scheduler === self, "LocalScheduler does not support task sharing")
        _ready.enqueue(task)
    }

    @inlinable
    public func didReceiveSignal(_ task: Task) {
        // Prevent the scheduler from closing and missing the task by
        // incrementing the count of threads in this critical section.
        if State.fetchAdd(&_state, 1, order: .acqrel).isClosed {
            // The scheduler is already closed and the task has been
            // destroyed by virtue of it being in the `active` list.
            return
        }

        _ready.enqueue(task)

        // Decrement the count to unblock the scheduler from closing.
        // We are now guaranteed the task will be seen and destroyed
        // if another thread is in `destroy()`.
        if State.fetchSub(&_state, 1, order: .acqrel).isClosed {
            // No need to send a notification if the scheduler has closed
            return
        }

        _waker.signal()
    }
}
