//
//  SinkSendAllFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct SendAll<S: StreamConvertible, Base: SinkProtocol>: FutureProtocol where Base.Input == S.StreamType.Output {
        public typealias Stream = S.StreamType
        public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

        @usableFromInline
        enum _State {
            case pending(Base, S)
            case polling(Base, Stream)
            case sending(Base, Stream, Stream.Output)
            case flushing(Base)
            case closing(Base)
            case done
        }

        @usableFromInline var _state: _State
        @usableFromInline var _shouldClose: Bool

        @inlinable
        public init(base: Base, stream: S, close: Bool) {
            _state = .pending(base, stream)
            _shouldClose = close
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch _state {
                case .pending(let base, let stream):
                    _state = .polling(base, stream.makeStream())
                    continue

                case .polling(let base, var stream):
                    switch stream.pollNext(&context) {
                    case .ready(.some(let item)):
                        _state = .sending(base, stream, item)
                        continue
                    case .ready(.none) where _shouldClose:
                        _state = .closing(base)
                        continue
                    case .ready(.none):
                        _state = .flushing(base)
                        continue
                    case .pending:
                        _state = .polling(base, stream)
                        return .pending
                    }

                case .sending(var base, let stream, let item):
                    switch base.pollSend(&context, item) {
                    case .ready(.success):
                        _state = .polling(base, stream)
                        continue
                    case .ready(.failure(let completion)):
                        _state = .done
                        return .ready(.failure(completion))
                    case .pending:
                        _state = .sending(base, stream, item)
                        return .pending
                    }

                case .flushing(var base):
                    switch base.pollFlush(&context) {
                    case .ready(.success):
                        _state = .done
                        return .ready(.success(base))
                    case .ready(.failure(let completion)):
                        _state = .done
                        return .ready(.failure(completion))
                    case .pending:
                        _state = .flushing(base)
                        return .pending
                    }

                case .closing(var base):
                    switch base.pollClose(&context) {
                    case .ready(.success):
                        _state = .done
                        return .ready(.success(base))
                    case .ready(.failure(let completion)):
                        _state = .done
                        return .ready(.failure(completion))
                    case .pending:
                        _state = .closing(base)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
