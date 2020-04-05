//
//  MapInputSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct MapInput<Input, Base: SinkProtocol>: SinkProtocol {
        public typealias Failure = Base.Failure

        public typealias Adapt = (Input) -> Base.Input

        @usableFromInline var _base: Base
        @usableFromInline let _adapt: Adapt
        @usableFromInline var _item: Base.Input?

        @inlinable
        public init(base: Base, adapt: @escaping Adapt) {
            _base = base
            _adapt = adapt
        }

        @inlinable
        mutating func _sendItem(_ context: inout Context) -> PollSink<Failure> {
            guard let item = _item.move() else {
                return .ready(.success(()))
            }
            switch _base.pollSend(&context, item) {
            case .ready(.success):
                return .ready(.success(()))
            case .ready(.failure(let completion)):
                return .ready(.failure(completion))
            case .pending:
                _item = item
                return .pending
            }
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
            return _sendItem(&context).flatMap {
                assert(_item == nil)
                _item = _adapt(item)
                return _sendItem(&context)
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
            return _sendItem(&context).flatMap {
                assert(_item == nil)
                return _base.pollFlush(&context)
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
            return _sendItem(&context).flatMap {
                assert(_item == nil)
                return _base.pollClose(&context)
            }
        }
    }
}
