//
//  FlattenResultStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct FlattenResult<Success, Failure, Base: StreamProtocol>: StreamProtocol where Base.Output == Result<Result<Success, Failure>, Failure> {
        public typealias Output = Result<Success, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base: base) {
                $0.flatten()
            }
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}
