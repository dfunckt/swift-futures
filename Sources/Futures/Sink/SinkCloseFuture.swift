//
//  SinkCloseFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Close<Base: SinkProtocol>: FutureProtocol {
        public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch _base.pollClose(&context) {
            case .ready(.success):
                return .ready(.success(_base))
            case .ready(.failure(let completion)):
                return .ready(.failure(completion))
            case .pending:
                return .pending
            }
        }
    }
}
