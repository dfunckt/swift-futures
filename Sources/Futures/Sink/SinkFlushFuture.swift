//
//  SinkFlushFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public enum Flush<Base: SinkProtocol> {
        case polling(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .polling(base)
        }
    }
}

extension Sink._Private.Flush: FutureProtocol {
    public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .polling(var base):
            switch base.pollFlush(&context) {
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
