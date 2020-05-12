//
//  FlattenResultFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct FlattenResult<Success, Failure, Base: FutureProtocol>: FutureProtocol where Base.Output == Result<Result<Success, Failure>, Failure> {
        public typealias Output = Result<Success, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base: base) {
                $0.flatten()
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
