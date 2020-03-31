//
//  ChannelImpl.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

extension Channel._Private {
    @usableFromInline
    final class Impl<C: ChannelProtocol> {
        @usableFromInline typealias Item = C.Buffer.Item

        @usableFromInline
        struct State: AtomicBitset {
            // LSB is the "open" bit.
            @usableFromInline var rawValue: AtomicUInt.RawValue

            @inlinable
            @_transparent
            init(rawValue: AtomicUInt.RawValue) {
                self.rawValue = rawValue
            }
        }

        @usableFromInline var _state: State.RawValue = 0
        @usableFromInline let _buffer: C.Buffer
        @usableFromInline let _senders: C.Park
        @usableFromInline let _receiver = AtomicWaker()

        @inlinable
        init(buffer: C.Buffer, park: C.Park) {
            State.initialize(&_state, to: 0)
            _buffer = buffer
            _senders = park
        }

        @inlinable
        var capacity: Int {
            return _buffer.capacity
        }
    }
}

extension Channel._Private.Impl.State {
    @inlinable static var closed: Self { 1 }

    @inlinable
    @_transparent
    static func count(_ value: RawValue) -> Self {
        .init(rawValue: value << 1)
    }

    @inlinable
    var isClosed: Bool {
        @_transparent get { contains(.closed) }
        @_transparent set { rawValue ^= (newValue ? 1 : 0) }
    }

    @inlinable
    var count: RawValue {
        @_transparent get { rawValue >> 1 }
        @_transparent set { rawValue = newValue << 1 }
    }
}

extension Channel._Private.Impl {
    @usableFromInline
    enum SendError: Swift.Error {
        case atCapacity
        case cancelled
        case retry
    }
}

extension Channel._Private.Impl {
    @inlinable
    func trySend(_ item: Item) -> Result<Void, SendError> {
        var backoff = Backoff()
        var curr = State.load(&_state)

        while true {
            var state = curr
            if state.isClosed {
                return .failure(.cancelled)
            }
            if state.count >= _buffer.capacity {
                return .failure(.atCapacity)
            }

            if !C.Buffer.supportsMultipleSenders {
                // Fast-path for Passthrough, Unbuffered and Buffered channels.
                // We synchronize around the item count for these channels.
                _buffer.push(item)

                if !C.Buffer.isPassthrough {
                    if State.fetchAdd(&_state, .count(1)).count == 0 {
                        _receiver.signal()
                    }
                    return .success(())
                }

                // Passthrough-only path
                state.count = 1
                if State.exchange(&_state, state).isClosed {
                    state.count = 0
                    state.isClosed = true
                    State.store(&_state, state)
                    return .failure(.cancelled)
                }
                return .success(())
            }

            // Shared-only path
            // We synchronize around the buffer for this channel

            state.count += 1

            guard State.compareExchange(&_state, &curr, state) else {
                if backoff.isComplete {
                    return .failure(.retry)
                }
                backoff.snooze()
                continue
            }

            _buffer.push(item)

            if state.count == 1 || state.count == _buffer.capacity {
                _receiver.signal()
            }

            return .success(())
        }
    }

    @inlinable
    func pollSend(_ context: inout Context, _ item: Item) -> Poll<Result<Void, Channel.Error>> {
        switch trySend(item) {
        case .success:
            return .ready(.success(()))
        case .failure(.atCapacity):
            assert(C.Buffer.isBounded)
            return _pollSendSlow(&context, item)
        case .failure(.retry):
            return context.yield()
        case .failure(.cancelled):
            return .ready(.failure(.cancelled))
        }
    }

    @usableFromInline
    func _pollSendSlow(_ context: inout Context, _ item: Item) -> Poll<Result<Void, Channel.Error>> {
        _senders.park(context.waker)

        switch trySend(item) {
        case .success:
            return .ready(.success(()))
        case .failure(.atCapacity):
            return .pending
        case .failure(.retry):
            return context.yield()
        case .failure(.cancelled):
            return .ready(.failure(.cancelled))
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func tryRecv() -> Result<Item?, Channel.Error> {
        let item: Item

        if !C.Buffer.supportsMultipleSenders {
            // Fast-path for Passthrough, Unbuffered and Buffered channels.
            // See trySend().
            let state = State.load(&_state)
            if state.count == 0 {
                if state.isClosed {
                    return .failure(.cancelled)
                }
                return .success(nil)
            }
            item = _buffer.pop()! // swiftlint:disable:this force_unwrapping
        } else {
            // Path for Shared channel
            guard let _item = _buffer.pop() else {
                let state = State.load(&_state)
                if state.isClosed {
                    return .failure(.cancelled)
                }
                if C.Buffer.isBounded {
                    _senders.notifyOne()
                }
                return .success(nil)
            }
            item = _item
        }

        if State.fetchSub(&_state, .count(1)).count == 1 {
            _senders.notifyFlush()
        }

        if C.Buffer.isBounded {
            _senders.notifyOne()
        }

        return .success(item)
    }

    @inlinable
    func pollRecv(_ context: inout Context) -> Poll<Item?> {
        switch tryRecv() {
        case .success(.some(let item)):
            return .ready(item)
        case .success(.none):
            return _pollRecvSlow(&context)
        case .failure(.cancelled):
            return .ready(nil)
        }
    }

    @usableFromInline
    func _pollRecvSlow(_ context: inout Context) -> Poll<Item?> {
        _receiver.register(context.waker)

        switch tryRecv() {
        case .success(.some(let item)):
            return .ready(item)
        case .success(.none):
            return .pending
        case .failure(.cancelled):
            return .ready(nil)
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func tryFlush() -> Result<Bool, Channel.Error> {
        let state = State.load(&_state)
        if state.isClosed {
            return .failure(.cancelled)
        }
        if state.count == 0 {
            return .success(true)
        }
        _receiver.signal()
        return .success(false)
    }

    @inlinable
    func pollFlush(_ context: inout Context) -> Poll<Result<Void, Channel.Error>> {
        switch tryFlush() {
        case .success(true):
            return .ready(.success(()))
        case .success(false):
            return _pollFlushSlow(&context)
        case .failure(.cancelled):
            return .ready(.failure(.cancelled))
        }
    }

    @usableFromInline
    func _pollFlushSlow(_ context: inout Context) -> Poll<Result<Void, Channel.Error>> {
        _senders.parkFlush(context.waker)

        switch tryFlush() {
        case .success(true):
            return .ready(.success(()))
        case .success(false):
            return .pending
        case .failure(.cancelled):
            return .ready(.failure(.cancelled))
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func close() {
        let state = State.fetchOr(&_state, .closed)
        if state.isClosed {
            return
        }
        if state.count == 0 {
            _receiver.signal()
        }
        _senders.notifyAll()
    }
}
