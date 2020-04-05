//
//  BufferSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Buffer<Base: SinkProtocol>: SinkProtocol {
        public typealias Input = Base.Input
        public typealias Failure = Base.Failure

        @usableFromInline var _base: Base
        @usableFromInline var _buffer: CircularBuffer<Input>
        @usableFromInline var _item: Input?

        @inlinable
        public init(base: Base, count: Int) {
            precondition(count > 0)
            _base = base
            _buffer = .init(capacity: count)
        }

        @usableFromInline
        @_transparent
        mutating func _sendItem(_ context: inout Context, item: Input) -> PollSink<Failure>? {
            switch _base.pollSend(&context, item) {
            case .ready(.success):
                return nil
            case .ready(.failure(let completion)):
                return .ready(.failure(completion))
            case .pending:
                _item = item
                return .pending
            }
        }

        @inlinable
        mutating func _sendBuffer(_ context: inout Context) -> PollSink<Failure> {
            if let item = _item.move(), let failure = _sendItem(&context, item: item) {
                return failure
            }
            while let item = _buffer.pop() {
                if let failure = _sendItem(&context, item: item) {
                    return failure
                }
            }
            return .ready(.success(()))
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
            return _sendBuffer(&context).flatMap {
                if _buffer.tryPush(item) {
                    return .ready(.success(()))
                }
                return .pending
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
            return _sendBuffer(&context).flatMap {
                assert(_buffer.isEmpty)
                assert(_item == nil)
                return _base.pollFlush(&context)
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
            return _sendBuffer(&context).flatMap {
                assert(_buffer.isEmpty)
                assert(_item == nil)
                return _base.pollFlush(&context)
            }
        }
    }
}
