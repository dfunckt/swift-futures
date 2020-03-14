//
//  BufferStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Buffer<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = [Base.Output]

        @usableFromInline
        enum _State {
            case pending(Base, CircularBuffer<Base.Output>)
            case complete
            case done
        }

        @usableFromInline var _state: _State

        @inlinable
        public init(base: Base, count: Int) {
            _state = .pending(base, .init(capacity: count))
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch _state {
            case .pending(var base, var buffer):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        if buffer.tryPush(output) {
                            continue
                        }
                        let elements = buffer.moveElements()
                        let enqueued = buffer.tryPush(output)
                        assert(enqueued)
                        _state = .pending(base, buffer)
                        return .ready(elements)

                    case .ready(.none):
                        _state = .complete
                        return .ready(buffer.moveElements())

                    case .pending:
                        _state = .pending(base, buffer)
                        return .pending
                    }
                }

            case .complete:
                _state = .done
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
