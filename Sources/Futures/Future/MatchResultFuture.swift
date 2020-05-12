//
//  MatchResultFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct MatchResult<Output, Success, Failure, Base: FutureProtocol>: FutureProtocol where Base.Output == Result<Success, Failure> {
        public typealias SuccessHandler = (Success) -> Output
        public typealias FailureHandler = (Failure) -> Output

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
            _base = .init(base: base) {
                $0.match(success: success, failure: failure)
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
