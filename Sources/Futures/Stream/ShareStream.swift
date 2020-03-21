//
//  ShareStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Stream._Private {
    public final class Share<Base: StreamProtocol>: StreamConvertible {
        public typealias Output = Base.Output

        @usableFromInline var _base: Base
        @usableFromInline let _state = _AtomicState(.idle)
        @usableFromInline let _waker: _Waker

        @usableFromInline var _events = AdaptiveQueue<_Task>()
        @usableFromInline var _tasks = [_Task]()
        @usableFromInline let _tasksLock = UnfairLock()

        @usableFromInline var _expecting: AtomicInt.RawValue = 0
        @usableFromInline var _element: Output?
        @usableFromInline var _buffer: _ReplayBuffer<Output>

        @inlinable
        public init(base: Base, replay: Stream.ReplayStrategy) {
            _base = base
            _waker = .init(_state)
            _buffer = .init(strategy: replay)
            AtomicInt.initialize(&_expecting, to: 0)
        }

        public final class Receiver: StreamProtocol, Cancellable {
            @usableFromInline let _stream: Share
            @usableFromInline let _task: _Task
            @usableFromInline var _initial: Array<Output>.Iterator

            @inlinable
            init(stream: Share, task: _Task, initial: [Output]) {
                _stream = stream
                _task = task
                _initial = initial.makeIterator()
            }

            @inlinable
            deinit {
                _stream._receiverCancelled(_task)
            }

            @inlinable
            public func cancel() {
                _stream._receiverCancelled(_task)
            }

            @inlinable
            public func pollNext(_ context: inout Context) -> Poll<Output?> {
                if let element = _initial.next() {
                    return .ready(element)
                }
                return _stream._pollNext(&context, task: _task)
            }
        }

        @inlinable
        public func makeStream() -> Receiver {
            let task = _Task()
            let elements: [Output] = _tasksLock.sync {
                _events.push(task)
                return _buffer.copyElements()
            }
            return .init(stream: self, task: task, initial: elements)
        }

        @inlinable
        public func eraseToAnySharedStream() -> AnySharedStream<Output> {
            return .init(self)
        }

        @inlinable
        public func eraseToAnyMulticastStream() -> AnyMulticastStream<Output> {
            return .init(self)
        }
    }
}

// MARK: - Private -

extension Stream._Private.Share {
    @usableFromInline
    enum _State: UInt {
        case idle
        case polling
        case waiting
        case notifying
        case broadcasting
    }

    @usableFromInline typealias _AtomicState = AtomicEnum<_State>

    @usableFromInline
    final class _Task {
        @usableFromInline var result: AtomicBool.RawValue = false

        private let _waker = Mutex(WakerProtocol?.none)

        @inlinable
        init() {
            AtomicBool.initialize(&result, to: false)
        }

        @usableFromInline
        func register(_ waker: WakerProtocol) {
            _waker.store(waker)
        }

        @usableFromInline
        func reset() {
            _waker.store(nil)
        }

        @usableFromInline
        @discardableResult
        func notify() -> Bool {
            if let waker = _waker.move() {
                waker.signal()
                return true
            }
            return false
        }
    }

    @usableFromInline
    final class _Waker: WakerProtocol {
        private let _state: _AtomicState
        @usableFromInline var _task: _Task?

        @usableFromInline
        init(_ state: _AtomicState) {
            _state = state
        }

        @usableFromInline
        func signal() {
            switch _state.compareExchange(.polling, .notifying) {
            case .polling:
                // Our task is currently polling and we received a signal
                // eagerly. Nothing else to do -- our task will see this
                // and repoll.
                break
            case .idle, .broadcasting:
                // We may have been stashed away and spuriously woken.
                // Ignore the notification.
                _task = nil
            case .waiting:
                // Our task is waiting to be signalled from the underlying
                // stream. Change the state to IDLE and signal the task.
                let task = _task.move()
                let previous = _state.exchange(.idle)
                assert(previous == .waiting)
                task!.notify() // swiftlint:disable:this force_unwrapping
            case .notifying:
                break
            }
        }
    }

    @inlinable
    func _receiverCancelled(_ task: _Task) {
        task.reset()

        _tasksLock.sync {
            if let index = _tasks.firstIndex(where: { $0 === task }) {
                _tasks.remove(at: index)
            }
            if AtomicBool.load(&task.result) {
                if AtomicInt.fetchSub(&_expecting, 1, order: .relaxed) == 1 {
                    let previous = _state.exchange(.idle)
                    assert(previous == .broadcasting)
                }
            }
            var iter = _tasks.makeIterator()
            while let task = iter.next() {
                if task.notify() {
                    return
                }
            }
        }
    }

    @inlinable
    func _setOutput(_ element: Output?, task: _Task) {
        _tasksLock.sync {
            // Register new receivers
            while let task = _events.pop() {
                _tasks.append(task)
            }

            if let element = _element {
                _buffer.push(element)
            }

            switch _tasks.count {
            case 1:
                // Fast path: this is the only receiver
                let previous = _state.exchange(.idle)
                assert(previous == .polling || previous == .notifying)
            case let count:
                // Switch the state and notify the other receivers.
                _element = element
                AtomicInt.store(&_expecting, count - 1, order: .relaxed)
                let previous = _state.exchange(.broadcasting)
                assert(previous == .polling || previous == .notifying)

                for t in _tasks where t !== task {
                    AtomicBool.store(&t.result, true)
                    t.notify()
                }
            }
        }
    }

    @inlinable
    func _tryReceive(_ task: _Task) -> Output?? {
        guard AtomicBool.exchange(&task.result, false) else {
            return nil
        }
        let element = _element
        if AtomicInt.fetchSub(&_expecting, 1, order: .relaxed) == 1 {
            // This is the last receiver to be consuming the
            // element; reset state back to IDLE.
            let previous = _state.exchange(.idle)
            assert(previous == .broadcasting)
        }
        return element
    }

    @inlinable
    func _pollNext(_ context: inout Context, task: _Task) -> Poll<Output?> {
        if let result = _tryReceive(task) {
            return .ready(result)
        }

        task.register(context.waker)

        switch _state.compareExchange(.idle, .polling) {
        case .idle:
            // Lock acquired; fall through.
            break

        case .polling, .waiting, .notifying:
            // Another task is currently polling;
            // register the waker so we'll be notified.
            return .pending

        case .broadcasting:
            // There is an element available; consume it.
            if let result = _tryReceive(task) {
                return .ready(result)
            }
            // We've seen the element before; wait for the next one.
            return .pending
        }

        _waker._task = task
        var context = context.withWaker(_waker)

        while true {
            switch _base.pollNext(&context) {
            case .ready(let result):
                _waker._task = nil
                _setOutput(result, task: task)
                return .ready(result)

            case .pending:
                // The next element isn't ready yet, so we have to wait.
                // We've registered our task above so we'll be notified.
                // Change the state to WAITING to prevent other receivers
                // from needlessly polling the underlying stream.
                switch _state.compareExchange(.polling, .waiting) {
                case .polling:
                    return .pending
                case .notifying:
                    // We were signalled just after we polled the stream.
                    // This changed the state to NOTIFYING. Re-poll once
                    // more expecting that we'll now get an element.
                    let previous = _state.exchange(.polling)
                    assert(previous == .notifying)
                default:
                    fatalError("unreachable")
                }
            }
        }
    }
}
