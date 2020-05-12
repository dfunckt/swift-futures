//
//  MatchEitherFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct MatchEither<Output, Left, Right, Base: FutureProtocol>: FutureProtocol where Base.Output == Either<Left, Right> {
        public typealias LeftHandler = (Left) -> Output
        public typealias RightHandler = (Right) -> Output

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, left: @escaping LeftHandler, right: @escaping RightHandler) {
            _base = .init(base: base) {
                $0.match(left: left, right: right)
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
