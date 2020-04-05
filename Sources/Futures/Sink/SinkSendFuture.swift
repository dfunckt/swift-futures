//
//  SinkSendFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public enum Send<Base: SinkProtocol>: FutureProtocol {
        public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

        case polling(Base, Base.Input)
        case done

        @inlinable
        public init(base: Base, item: Base.Input) {
            self = .polling(base, item)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .polling(var base, let item):
                switch base.pollSend(&context, item) {
                case .ready(.success):
                    self = .done
                    return .ready(.success(base))
                case .ready(.failure(let completion)):
                    self = .done
                    return .ready(.failure(completion))
                case .pending:
                    self = .polling(base, item)
                    return .pending
                }
            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
