//
//  ScheduledTask.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

public final class ScheduledTask<Scheduler: SchedulerProtocol> {
    public typealias Future = (inout Context) -> Poll<Scheduler.Output>

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

    @usableFromInline var _state: State.RawValue = 0

    // These fields belong to the scheduler that owns this task, ie. the one
    // `bind(_:)` was called on. Task never touches these.
    public typealias AtomicTask = AtomicReference<ScheduledTask>
    public var _nextReady: AtomicTask.RawValue = 0
    public var prevActive: ScheduledTask?
    public var nextActive: ScheduledTask?

    // swiftlint:disable implicitly_unwrapped_optional
    @usableFromInline weak var _scheduler: Scheduler?
    @usableFromInline var _future: Future!
    // swiftlint:enable implicitly_unwrapped_optional

    @usableFromInline
    internal init(future: Future?) {
        _future = future
        State.initialize(&_state, to: .notified)
        AtomicTask.initialize(&_nextReady, to: nil)
        _trace("=> init")
    }

    deinit {
        _trace("=> deinit")
//        assert(_scheduler == nil)
        assert(_future == nil)
    }
}

extension ScheduledTask {
    @inlinable
    public var nextReady: ScheduledTask? {
        @_transparent get {
            AtomicTask.load(&_nextReady, order: .relaxed)
        }
        @_transparent set {
            AtomicTask.store(&_nextReady, newValue, order: .relaxed)
        }
    }
}

extension ScheduledTask {
    @inlinable
    public static func allocate(future: @escaping Future) -> Self {
        return .init(future: future)
    }

    /// This method must only be called by the scheduler that owns this task.
    @inlinable
    public func release() {
        _trace("=> release")
        _future = nil
        State.transitionToReleased(&_state)
    }

    /// This method must only be called by the scheduler that owns this task.
    @inlinable
    public func prepareForReuse(future: @escaping Future) {
        _trace("=> reuse")

        assert(_future == nil)
        _future = future

        // Reusing a task has ABA issues with regards to wakeups:
        // if the task is signalled after reuse from a reference
        // stored away somewhere from before reuse, it can cause
        // a spurious wakeup. This however is fine, as spurious
        // wakeups are allowed and expected. We could prevent this
        // by tracking generations but it's not worth the overhead.
        State.transitionFromReleased(&_state)
    }

    /// Destroy this task, making it unsuitable for subsequent reuse.
    ///
    /// This method must only be called by the scheduler that owns this task.
    @inlinable
    public func destroy() {
        let state = State.transitionToCancelled(&_state)
        _cancel(state)
    }
}

extension ScheduledTask {
    @inlinable
    func _cancel(_ state: State) {
        // may be called while the task is in any of the following states:
        //
        // 1. idle: the task is sitting idle waiting to be signalled
        // 2. notified: the task has been signalled and is being concurrently scheduled
        // 3. running: the task is being polled concurrently by another scheduler
        // 4. complete: `poll()` finished on the owning scheduler
        // 5. released: the task has already been released
        //
        // The problematic cases are (2) and (3).
        if state.contains(.complete | .released) {
            return
        }
        if !state.contains(.running) {
            _future = nil
        }
    }

    @inlinable
    public func poll(scheduler: Scheduler) -> Scheduler.Output? {
        _trace("=> poll")

        // may be called from any thread but *never* concurrently.

        // Transition to `running` to ensure exclusive access
        // to the task's state.
        let state = State.transitionToRunning(&_state)

        if state.contains(.cancelled) {
            _cancel(state)
            return nil
        }

        if _scheduler == nil {
            _trace("  => bind")
            // This is the first time this task is polled; bind it to
            // the given scheduler and store a reference. This needs no
            // synchronization because the scheduler reference is only
            // ever set once here and there are no waker references
            // around that could try to access it.
            scheduler.bind(self)
            _scheduler = scheduler
        }

        guard let sched = _scheduler else {
            fatalError("scheduler gone mid-poll")
        }

        if TRACE_TASK, _scheduler !== scheduler {
            _trace("=> poll remote")
        }

        var context = Context(waker: self)

        switch _future(&context) {
        case .ready(let output):
            _trace("  => ready")
            State.transitionToComplete(&_state)

            // The future completed. Pass it over to the scheduler
            // to arrange for releasing it.
            sched.release(self, from: scheduler)
            return output

        case .pending:
            // The future did not complete. Check whether the task
            // was notified while polling the future and immediately
            // reschedule it if so.
            if State.transitionToIdle(&_state).contains(.notified) {
                _trace("  => schedule")
                sched.schedule(self, from: scheduler)
            }
            return nil
        }
    }
}

extension ScheduledTask: WakerProtocol {
    @inlinable
    public func signal() {
        _trace("=> signal")
        if State.transitionToNotified(&_state).shouldEnqueue {
            _trace("  => schedule signal")
            _scheduler?.didReceiveSignal(self)
        }
    }
}

///
/// ```
///                IDLE <-----------------+
///                  |                    |
///               signal()             pending?
///                  v                    |
/// allocate()--> NOTIFIED --poll()--> RUNNING --ready?--> COMPLETE
///                  ^                    |                   |
///                  |                signalled?           release()
///                  |                    |                   v
///                  +--------------------+                RELEASED
///                  |                                        |
///                  |                                  prepareForReuse()
///                  |                                        |
///                  +----------------------------------------+
/// ```
///
extension ScheduledTask.State {
    @inlinable static var bitWidth: Int { 5 }

    @inlinable static var running: Self { 0b0000_0001 }
    @inlinable static var notified: Self { 0b0000_0010 }
    @inlinable static var complete: Self { 0b0000_0100 }
    @inlinable static var released: Self { 0b0000_1000 }
    @inlinable static var cancelled: Self { 0b0001_0000 }
    @inlinable static var destroyed: Self { 0b0010_0000 }

    @inlinable
    var shouldEnqueue: Bool {
        @_transparent get {
            return rawValue == 0
        }
    }
}

extension ScheduledTask.State {
    @inlinable
    static func transitionToNotified(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .notified
        let prev = fetchOr(ptr, delta)
        return prev
    }

    @inlinable
    @discardableResult
    static func transitionToRunning(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .notified | .running
        let prev = fetchXor(ptr, delta)
        assert(prev.contains(.notified), "task is being polled but is not runnable (\(prev))")
        assert(!prev.contains(.running), "task is being polled concurrently (\(prev))")
        return prev
    }

    @inlinable
    @discardableResult
    static func transitionToIdle(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .running
        let prev = fetchXor(ptr, delta)
        assert(prev.contains(.running), "expected running; found: \(prev)")
        return prev
    }

    @inlinable
    @discardableResult
    static func transitionToComplete(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .running | .complete
        let prev = fetchXor(ptr, delta)
        assert(prev.contains(.running), "expected running; found: \(prev)")
        assert(!prev.contains(.complete), "expected not complete; found: \(prev)")
        return prev
    }

    @inlinable
    @discardableResult
    static func transitionToReleased(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .released
        let prev = fetchOr(ptr, delta)
        assert(prev.contains(.complete), "expected complete; found: \(prev)")
        return prev
    }

    @inlinable
    @discardableResult
    static func transitionFromReleased(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .notified
        let prev = exchange(ptr, delta)
        assert(!prev.contains(.destroyed), "cannot reuse a destroyed task (\(prev))")
        assert(prev.contains(.released), "task must be released before it is reused (\(prev))")
        return prev
    }

    @inlinable
    static func transitionToCancelled(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .cancelled
        let prev = fetchOr(ptr, delta)
        return prev
    }

    @inlinable
    static func transitionToDestroyed(_ ptr: RawValue.AtomicPointer) -> Self {
        let delta: Self = .destroyed
        let prev = fetchOr(ptr, delta)
        assert(prev.contains(.cancelled), "task must be cancelled before it is destroyed (\(prev))")
        return prev
    }
}

extension ScheduledTask: Hashable {
    @inlinable
    public static func == (lhs: ScheduledTask<Scheduler>, rhs: ScheduledTask<Scheduler>) -> Bool {
        return lhs === rhs
    }

    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

// Turn on logging of task state transitions in DEBUG builds.
// Warning: will dump potentially tons of output to stdout.
@usableFromInline let TRACE_TASK = false

extension ScheduledTask {
    #if DEBUG
    @inlinable
    @_transparent
    func _trace(_ str: StaticString) {
        if TRACE_TASK {
            print(pointerAddressForDisplay(self), State.load(&_state), str)
        }
    }

    #else

    @inlinable
    @_transparent
    func _trace(_: StaticString) {}
    #endif
}
