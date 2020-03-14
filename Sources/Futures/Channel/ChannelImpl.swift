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
        struct State {
            @usableFromInline var isOpen: Bool
            @usableFromInline var count: Int

            @inlinable
            static var OPEN_MASK: UInt {
                return UInt.max - (UInt.max >> 1)
            }

            @inlinable
            static var COUNT_MASK: UInt {
                return ~OPEN_MASK
            }

            @inlinable
            init(rawValue: UInt) {
                isOpen = (rawValue & State.OPEN_MASK) == State.OPEN_MASK
                count = Int(bitPattern: rawValue & State.COUNT_MASK)
            }

            @inlinable
            var rawValue: UInt {
                var value = UInt(bitPattern: count)
                if isOpen {
                    value |= State.OPEN_MASK
                }
                return value
            }
        }

        @usableFromInline var _state: AtomicUInt.RawValue = State.OPEN_MASK
        @usableFromInline let _buffer: C.Buffer
        @usableFromInline let _senders: C.Park
        @usableFromInline let _receiver = _AtomicWaker()

        @inlinable
        init(buffer: C.Buffer, park: C.Park) {
            AtomicUInt.initialize(&_state, to: State.OPEN_MASK)
            _buffer = buffer
            _senders = park
        }

        @inlinable
        var capacity: Int {
            return _buffer.capacity
        }

        @inlinable
        func trySend(_ item: Item) -> Result<Bool, Channel.Error> {
            var backoff = Backoff()
            var curr = AtomicUInt.load(&_state)

            while true {
                var state = State(rawValue: curr)
                if !state.isOpen {
                    return .failure(.cancelled)
                }
                if state.count >= _buffer.capacity {
                    return .success(false)
                }

                if !_buffer.supportsMultipleSenders {
                    // Fast-path for Passthrough, Unbuffered and Buffered channels.
                    // We synchronize around the item count for these channels.
                    _buffer.push(item)

                    if !_buffer.isPassthrough {
                        if State(rawValue: AtomicUInt.fetchAdd(&_state, 1)).count == 0 {
                            _receiver.signal()
                        }
                        return .success(true)
                    }

                    // Passthrough-only path
                    state.count = 1
                    if !State(rawValue: AtomicUInt.exchange(&_state, state.rawValue)).isOpen {
                        state.count = 0
                        state.isOpen = false
                        AtomicUInt.store(&_state, state.rawValue)
                        return .failure(.cancelled)
                    }
                    return .success(true)
                }

                // Shared-only path
                // We synchronize around the buffer for this channel

                state.count += 1

                guard AtomicUInt.compareExchange(&_state, &curr, state.rawValue) else {
                    if backoff.yield() {
                        backoff.reset()
                    }
                    continue
                }

                _buffer.push(item)

                if state.count == 1 || state.count == _buffer.capacity {
                    _receiver.signal()
                }

                return .success(true)
            }
        }

        @inlinable
        func pollSend(_ context: inout Context, _ item: Item) -> Poll<Result<Void, Channel.Error>> {
            switch trySend(item) {
            case .success(true):
                return .ready(.success(()))
            case .success(false):
                assert(_buffer.isBounded)
                return _pollSendSlow(&context, item)
            case .failure(.cancelled):
                return .ready(.failure(.cancelled))
            }
        }

        @usableFromInline
        func _pollSendSlow(_ context: inout Context, _ item: Item) -> Poll<Result<Void, Channel.Error>> {
            _senders.park(context.waker)

            switch trySend(item) {
            case .success(true):
                return .ready(.success(()))
            case .success(false):
                return .pending
            case .failure(.cancelled):
                return .ready(.failure(.cancelled))
            }
        }

        @inlinable
        func tryRecv() -> Result<Item?, Channel.Error> {
            let item: Item

            if !_buffer.supportsMultipleSenders {
                // Fast-path for Passthrough, Unbuffered and Buffered channels.
                // See trySend().
                let state = State(rawValue: AtomicUInt.load(&_state))
                if state.count == 0 {
                    if !state.isOpen {
                        return .failure(.cancelled)
                    }
                    return .success(nil)
                }
                item = _buffer.pop()! // swiftlint:disable:this force_unwrapping
            } else {
                // Path for Shared channel
                guard let _item = _buffer.pop() else {
                    let state = State(rawValue: AtomicUInt.load(&_state))
                    if !state.isOpen {
                        return .failure(.cancelled)
                    }
                    if _buffer.isBounded {
                        _senders.notifyOne()
                    }
                    return .success(nil)
                }
                item = _item
            }

            if State(rawValue: AtomicUInt.fetchSub(&_state, 1)).count == 1 {
                _senders.notifyFlush()
            }

            if _buffer.isBounded {
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

        @inlinable
        func tryFlush() -> Result<Bool, Channel.Error> {
            let state = State(rawValue: AtomicUInt.load(&_state))
            if !state.isOpen {
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

        @inlinable
        func close() {
            let state = State(rawValue: AtomicUInt.fetchAnd(&_state, State.COUNT_MASK))
            if !state.isOpen {
                return
            }
            if state.count == 0 {
                _receiver.signal()
            }
            _senders.notifyAll()
        }
    }
}
