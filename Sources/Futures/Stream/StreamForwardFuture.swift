//
//  StreamForwardFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Forward<S: SinkConvertible, Base: StreamProtocol> where Base.Output == S.SinkType.Input {
        @usableFromInline
        enum _State {
            case pending(Base, S)
            case polling(Base, S.SinkType)
            case sending(Base, S.SinkType, Base.Output)
            case flushing(S.SinkType)
            case closing(S.SinkType)
            case done
        }

        @usableFromInline var _state: _State
        @usableFromInline var _shouldClose: Bool

        @inlinable
        public init(base: Base, sink: S, close: Bool) {
            _state = .pending(base, sink)
            _shouldClose = close
        }
    }
}

extension Stream._Private.Forward: FutureProtocol {
    public typealias Output = Result<Void, S.SinkType.Failure>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch _state {
            case .pending(let base, let sink):
                _state = .polling(base, sink.makeSink())
                continue

            case .polling(var base, let sink):
                switch base.pollNext(&context) {
                case .ready(.some(let element)):
                    _state = .sending(base, sink, element)
                    continue
                case .ready(.none) where _shouldClose:
                    _state = .closing(sink)
                    continue
                case .ready(.none):
                    _state = .flushing(sink)
                    continue
                case .pending:
                    _state = .polling(base, sink)
                    return .pending
                }

            case .sending(let base, var sink, let item):
                switch sink.pollSend(&context, item) {
                case .ready(.success):
                    _state = .polling(base, sink)
                    continue
                case .ready(.failure(.closed)):
                    _state = .done
                    return .ready(.success(()))
                case .ready(.failure(.failure(let error))):
                    _state = .done
                    return .ready(.failure(error))
                case .pending:
                    _state = .sending(base, sink, item)
                    return .pending
                }

            case .flushing(var sink):
                switch sink.pollFlush(&context) {
                case .ready(.success):
                    _state = .done
                    return .ready(.success(()))
                case .ready(.failure(.closed)):
                    _state = .done
                    return .ready(.success(()))
                case .ready(.failure(.failure(let error))):
                    _state = .done
                    return .ready(.failure(error))
                case .pending:
                    _state = .flushing(sink)
                    return .pending
                }

            case .closing(var sink):
                switch sink.pollClose(&context) {
                case .ready(.success):
                    _state = .done
                    return .ready(.success(()))
                case .ready(.failure(.closed)):
                    _state = .done
                    return .ready(.success(()))
                case .ready(.failure(.failure(let error))):
                    _state = .done
                    return .ready(.failure(error))
                case .pending:
                    _state = .closing(sink)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
