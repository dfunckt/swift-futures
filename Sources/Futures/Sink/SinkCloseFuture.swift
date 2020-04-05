//
//  SinkCloseFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public enum Close<Base: SinkProtocol>: FutureProtocol {
        public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

        case polling(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .polling(base)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .polling(var base):
                switch base.pollClose(&context) {
                case .ready(.success):
                    self = .done
                    return .ready(.success(base))
                case .ready(.failure(let completion)):
                    self = .done
                    return .ready(.failure(completion))
                case .pending:
                    self = .polling(base)
                    return .pending
                }
            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
