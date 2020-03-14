//
//  BufferSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Buffer<Base: SinkProtocol>: SinkProtocol {
        public typealias Input = Base.Input
        public typealias Output = Result<Void, Sink.Completion<Base.Failure>>

        @usableFromInline let _capacity: Int
        @usableFromInline var _base: Base
        @usableFromInline var _buffer: CircularBuffer<Input>
        @usableFromInline var _item: Input?

        @inlinable
        public init(base: Base, count: Int) {
            precondition(count > 0)
            _capacity = count
            _base = base
            _buffer = .init(capacity: count)
        }

        @inlinable
        mutating func _sendBuffer(_ context: inout Context) -> Poll<Output> {
            if let item = _item.move() {
                switch _base.pollSend(&context, item) {
                case .ready(.success):
                    break
                case .ready(.failure(let completion)):
                    return .ready(.failure(completion))
                case .pending:
                    _item = item
                    return .pending
                }
            }
            while let item = _buffer.pop() {
                switch _base.pollSend(&context, item) {
                case .ready(.success):
                    continue
                case .ready(.failure(let completion)):
                    return .ready(.failure(completion))
                case .pending:
                    _item = item
                    return .pending
                }
            }
            return .ready(.success(()))
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output> {
            if case .ready(.failure(let completion)) = _sendBuffer(&context) {
                return .ready(.failure(completion))
            }
            if _buffer.count >= _capacity {
                return .pending
            }
            _buffer.push(item)
            return .ready(.success(()))
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> Poll<Output> {
            switch _sendBuffer(&context) {
            case .ready(.success):
                assert(_buffer.isEmpty)
                assert(_item == nil)
                return _base.pollFlush(&context)
            case .ready(.failure(let completion)):
                return .ready(.failure(completion))
            case .pending:
                return .pending
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> Poll<Output> {
            switch _sendBuffer(&context) {
            case .ready(.success):
                assert(_buffer.isEmpty)
                assert(_item == nil)
                return _base.pollClose(&context)
            case .ready(.failure(let completion)):
                return .ready(.failure(completion))
            case .pending:
                return .pending
            }
        }
    }
}
