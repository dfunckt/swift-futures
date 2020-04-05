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
            @usableFromInline typealias RawValue = AtomicUInt.RawValue
            @usableFromInline var rawValue: RawValue

            @inlinable
            @_transparent
            init(rawValue: RawValue) {
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
    }
}

extension Channel._Private.Impl.State {
    @inlinable static var receiverClose: Self {
        @_transparent get { 0b01 }
    }

    @inlinable static var senderClose: Self {
        @_transparent get { 0b10 }
    }

    @inlinable
    @_transparent
    static func count(_ value: RawValue) -> Self {
        .init(rawValue: value << 2)
    }

    @inlinable
    var count: RawValue {
        @_transparent get { rawValue >> 2 }
    }

    @inlinable
    var isClosed: Bool {
        @_transparent get { contains(.receiverClose | .senderClose) }
    }

    @inlinable
    var isReceiverClosed: Bool {
        @_transparent get { contains(.receiverClose) }
    }

    @inlinable
    var isSenderClosed: Bool {
        @_transparent get { contains(.senderClose) }
    }
}

extension Channel._Private.Impl {
    @usableFromInline
    enum BufferResult<T> {
        case success(State, T)
        case cancelled
        case retry
    }
}

extension Channel._Private.Impl {
    @inlinable
    func tryRecv() -> BufferResult<Item?> {
        var backoff = Backoff()

        while true {
            // First check the buffer, then decrement count if
            // we get an item.
            guard let item = _buffer.pop() else {
                // No items; either the buffer is empty or a sender
                // incremented count but didn't get round to pushing
                // the item into the buffer yet; retry a few times.
                let state = State.load(&_state)
                assert(
                    !state.isReceiverClosed,
                    "receiver unexpectedly closed the channel"
                )
                if state.count == 0 {
                    // Buffer is literally empty. See if the channel is
                    // closed and signal cancellation. We always allow
                    // the receiver to flush the channel first, so this
                    // is the right time.
                    guard !state.isClosed else {
                        return .cancelled
                    }
                    return .success(state, nil)
                }

                // A sender incremented count but didn't get to
                // push the item yet; retry a few times.
                guard !backoff.isComplete else {
                    return .retry
                }
                backoff.snooze()
                continue
            }

            let state = State.fetchSub(&_state, .count(1))

            return .success(state, item)
        }
    }

    @inlinable
    func pollRecv(_ context: inout Context) -> Poll<Item?> {
        switch tryRecv() {
        case .success(let state, .some(let item)):
            _didRecvItem(state)
            return .ready(item)
        case .success(_, .none):
            return _pollRecvSlow(&context)
        case .cancelled:
            return .ready(nil)
        case .retry:
            return context.yield()
        }
    }

    @usableFromInline
    func _pollRecvSlow(_ context: inout Context) -> Poll<Item?> {
        _receiver.register(context.waker)

        switch tryRecv() {
        case .success(let state, .some(let item)):
            _receiver.clear()
            _didRecvItem(state)
            return .ready(item)
        case .success(_, .none):
            _senders.notifyOne()
            return .pending
        case .cancelled:
            _receiver.clear()
            return .ready(nil)
        case .retry:
            _receiver.clear()
            return context.yield()
        }
    }

    @usableFromInline
    @_transparent
    func _didRecvItem(_ state: State) {
        if state.count == 1 {
            // The buffer is now empty; notify waiters
            _senders.notifyFlush()
        }
        if state.count == _buffer.capacity {
            // If this is a bounded channel and it was at capacity,
            // then notify a sender that a slot has opened for sending
            // further items.
            _senders.notifyOne()
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func trySend(_ item: Item) -> BufferResult<Bool> {
        // First increment count, then push the item into the buffer.
        let state = State.fetchAdd(&_state, .count(1))

        guard !state.isClosed else {
            State.fetchSub(&_state, .count(1))
            return .cancelled
        }

        if state.count >= _buffer.capacity {
            let state = State.fetchSub(&_state, .count(1))
            guard !state.isClosed else {
                return .cancelled
            }
            // Passthrough channels overwrite previous items when at
            // capacity, so fallthrough if that's the case. Otherwise,
            // signal that the item failed to be sent.
            if !C.Buffer.isPassthrough {
                return .success(state, false)
            }
        }

        _buffer.push(item)

        return .success(state, true)
    }

    @inlinable
    func pollSend(_ context: inout Context, _ item: Item) -> Poll<C.Sender.Output> {
        switch trySend(item) {
        case .success(let state, true):
            _didSendItem(state)
            return .ready(.success(()))
        case .success(_, false):
            assert(C.Buffer.isBounded)
            return _pollSendSlow(&context, item)
        case .cancelled:
            return .ready(.failure(.closed))
        case .retry:
            return context.yield()
        }
    }

    @usableFromInline
    func _pollSendSlow(_ context: inout Context, _ item: Item) -> Poll<C.Sender.Output> {
        let handle = _senders.park(context.waker)

        switch trySend(item) {
        case .success(let state, true):
            handle.cancel()
            _didSendItem(state)
            return .ready(.success(()))
        case .success(_, false):
            return .pending
        case .cancelled:
            handle.cancel()
            return .ready(.failure(.closed))
        case .retry:
            handle.cancel()
            return context.yield()
        }
    }

    @usableFromInline
    @_transparent
    func _didSendItem(_ state: State) {
        if state.count == 0 {
            // If the channel was empty before this item we need to
            // signal the receiver, as it may be parked.
            _receiver.signal()
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func tryFlush() -> Result<Bool, Channel.Error> {
        let state = State.load(&_state)
        guard !state.isClosed else {
            return .failure(.cancelled)
        }
        return .success(state.count == 0)
    }

    @inlinable
    func pollFlush(_ context: inout Context) -> Poll<C.Sender.Output> {
        switch tryFlush() {
        case .success(true):
            return .ready(.success(()))
        case .success(false):
            return _pollFlushSlow(&context)
        case .failure(.cancelled):
            return .ready(.failure(.closed))
        }
    }

    @usableFromInline
    func _pollFlushSlow(_ context: inout Context) -> Poll<C.Sender.Output> {
        let handle = _senders.parkFlush(context.waker)

        switch tryFlush() {
        case .success(true):
            handle.cancel()
            return .ready(.success(()))
        case .success(false):
            return .pending
        case .failure(.cancelled):
            handle.cancel()
            return .ready(.failure(.closed))
        }
    }
}

extension Channel._Private.Impl {
    @inlinable
    func receiverClose() {
        let state = State.fetchOr(&_state, .receiverClose)
        guard !state.isClosed else {
            return
        }
        _senders.notifyAll()
    }

    @inlinable
    func senderClose() {
        let state = State.fetchOr(&_state, .senderClose)
        guard !state.isClosed else {
            return
        }
        if state.count == 0 {
            _receiver.signal()
        }
    }
}
