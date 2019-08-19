//
//  MulticastStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public final class Multicast<Base: StreamProtocol>: StreamConvertible {
        public typealias Output = Base.Output

        @usableFromInline
        final class _Task {
            @usableFromInline var result = false
            @usableFromInline var _waker: WakerProtocol?

            @inlinable
            init() {}

            @inlinable
            func register(_ waker: WakerProtocol) {
                _waker = waker
            }

            @usableFromInline
            @discardableResult
            func notify() -> Bool {
                if let waker = _waker.take() {
                    waker.signal()
                    return true
                }
                return false
            }
        }

        @usableFromInline
        enum _State {
            case idle
            case waiting(_Task)
            case broadcasting(Int, Output?)
            case done
        }

        @usableFromInline var _base: Base
        @usableFromInline var _buffer: _ReplayBuffer<Output>
        @usableFromInline var _state = _State.idle
        @usableFromInline var _tasks = [_Task]()

        @inlinable
        public init(base: Base, replay: Stream.ReplayStrategy) {
            _base = base
            _buffer = .init(strategy: replay)
        }

        public final class Receiver: StreamProtocol, Cancellable {
            @usableFromInline let _stream: Multicast
            @usableFromInline let _task: _Task
            @usableFromInline var _replay: Array<Output>.Iterator?

            @inlinable
            init(stream: Multicast, task: _Task, replay: [Output]) {
                _stream = stream
                _task = task
                _replay = replay.makeIterator()
            }

            deinit {
                _stream._receiverCancelled(_task)
            }

            public func cancel() {
                _stream._receiverCancelled(_task)
            }

            @inlinable
            public func pollNext(_ context: inout Context) -> Poll<Output?> {
                if let element = _replay?.next() {
                    return .ready(element)
                } else {
                    _replay = nil
                }
                switch _stream._pollNext(&context, task: _task) {
                case .ready(let output):
                    return .ready(output)
                case .pending:
                    _task.register(context.waker)
                    return .pending
                }
            }
        }

        @inlinable
        public func makeStream() -> Receiver {
            let task = _Task()
            let elements = _receiverAdded(task)
            return .init(stream: self, task: task, replay: elements)
        }

        @inlinable
        public func eraseToAnyMulticastStream() -> AnyMulticastStream<Output> {
            return .init(self)
        }
    }
}

// MARK: - Private -

extension Stream._Private.Multicast {
    @inlinable
    func _receiverAdded(_ task: _Task) -> [Output] {
        _tasks.append(task)
        return _buffer.copyElements()
    }

    private func _receiverCancelled(_ task: _Task) {
        if let index = _tasks.firstIndex(where: { $0 === task }) {
            _tasks.remove(at: index)
        }

        switch _state {
        case .idle:
            _notifyOne()

        case .done:
            break

        case .broadcasting(let count, let element):
            let count = task.result ? count - 1 : count
            if count == 0 {
                // This was the last task seeing this element. Reset state to
                // .idle and notify another task.
                _state = .idle
                _notifyOne()
            } else {
                assert(count > 0)
                _state = .broadcasting(count, element)
            }

        case .waiting(let waitingTask):
            if waitingTask === task {
                if let t = _tasks.first {
                    _state = .waiting(t)
                } else {
                    // We don't have another task to replace this one; reset
                    // state to .idle so that the next subscriber continues
                    // polling the underlying stream.
                    _state = .idle
                }
            }
        }
    }

    private func _notifyOne() {
        var iter = _tasks.makeIterator()
        while let task = iter.next() {
            if task.notify() {
                return
            }
        }
    }

    @inlinable
    func _pollStream(_ context: inout Context, _ task: _Task) -> Poll<Output?> {
        switch _base.pollNext(&context) {
        case .ready(let element):
            switch _tasks.count {
            case 1:
                _state = element == nil ? .done : .idle
            case let count:
                _state = .broadcasting(count - 1, element)
                for t in _tasks where t !== task {
                    t.result = true
                    t.notify()
                }
            }
            if let element = element {
                _buffer.push(element)
            }
            return .ready(element)
        case .pending:
            _state = .waiting(task)
            return .pending
        }
    }

    @inlinable
    func _pollNext(_ context: inout Context, task: _Task) -> Poll<Output?> {
        switch _state {
        case .idle:
            return _pollStream(&context, task)

        case .waiting(let waitingTask):
            if waitingTask === task {
                // We've been waiting on the stream and have since been
                // woken. Repoll the stream.
                return _pollStream(&context, task)
            }
            return .pending

        case .broadcasting(let count, let element):
            guard task.result else {
                // We've seen this element before
                return .pending
            }

            task.result = false

            switch count {
            case 1:
                _state = element == nil ? .done : .idle
            case let count:
                _state = .broadcasting(count - 1, element)
            }
            return .ready(element)

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
