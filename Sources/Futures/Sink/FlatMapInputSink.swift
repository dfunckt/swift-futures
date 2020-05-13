//
//  FlatMapInputSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct FlatMapInput<Input, U: StreamConvertible, Base: SinkProtocol>: SinkProtocol where Base.Input == U.StreamType.Output {
        public typealias Stream = U.StreamType
        public typealias Failure = Base.Failure

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
        mutating func _sendStream(_ context: inout Context) -> PollSink<Failure> {
            // send pending item, if any
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

            // drain the stream
            if var stream = _stream.move() {
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
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
            return _sendStream(&context).flatMap {
                assert(_item == nil)
                assert(_stream == nil)
                _stream = _adapt(item).makeStream()
                return .ready(.success(()))
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
            return _sendStream(&context).flatMap {
                assert(_item == nil)
                assert(_stream == nil)
                return _base.pollFlush(&context)
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
            return _sendStream(&context).flatMap {
                assert(_item == nil)
                assert(_stream == nil)
                return _base.pollClose(&context)
            }
        }
    }
}
