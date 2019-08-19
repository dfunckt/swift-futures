//
//  SinkSendFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Send<Base: SinkProtocol>: FutureProtocol {
        public typealias Output = Result<Base, Sink.Completion<Base.Failure>>

        @usableFromInline var _base: Base
        @usableFromInline let _item: Base.Input

        @inlinable
        public init(base: Base, item: Base.Input) {
            _base = base
            _item = item
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch _base.pollSend(&context, _item) {
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
