//
//  FlatMapSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct FlatMap<Input, U: StreamConvertible, Base: SinkProtocol>: SinkProtocol where Base.Input == U.StreamType.Output {
        public typealias Stream = U.StreamType
        public typealias Output = Base.Output

        public typealias Adapt = (Input) -> U

        @usableFromInline var _base: Base
        @usableFromInline let _adapt: Adapt
        @usableFromInline var _stream: Stream?
        @usableFromInline var _item: Stream.Output?

        @inlinable
        public init(base: Base, adapt: @escaping Adapt) {
            _base = base
            _adapt = adapt
        }

        @inlinable
        mutating func _pollStream(_ context: inout Context) -> Poll<Output> {
            if let item = _item.move() {
                // send pending item, if any
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

            if var stream = _stream.move() {
                // drain the stream
                while true {
                    switch stream.pollNext(&context) {
                    case .ready(.some(let item)):
                        switch _base.pollSend(&context, item) {
                        case .ready(.success):
                            continue
                        case .ready(.failure(let completion)):
                            return .ready(.failure(completion))
                        case .pending:
                            _stream = stream
                            _item = item
                            return .pending
                        }
                    case .ready(.none):
                        return .ready(.success(()))
                    case .pending:
                        _stream = stream
                        return .pending
                    }
                }
            }

            return .ready(.success(()))
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output> {
            switch _pollStream(&context) {
            case .ready(.success):
                assert(_item == nil)
                assert(_stream == nil)
                _stream = _adapt(item).makeStream()
                return .ready(.success(()))
            case .ready(.failure(let error)):
                return .ready(.failure(error))
            case .pending:
                return .pending
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> Poll<Output> {
            switch _pollStream(&context) {
            case .ready(.success):
                assert(_item == nil)
                assert(_stream == nil)
                return _base.pollFlush(&context)
            case .ready(.failure(let error)):
                return .ready(.failure(error))
            case .pending:
                return .pending
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> Poll<Output> {
            switch _pollStream(&context) {
            case .ready(.success):
                assert(_item == nil)
                assert(_stream == nil)
                return _base.pollClose(&context)
            case .ready(.failure(let error)):
                return .ready(.failure(error))
            case .pending:
                return .pending
            }
        }
    }
}
