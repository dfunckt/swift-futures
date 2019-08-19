//
//  MatchResultFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum MatchResult<Output, Base: FutureProtocol>: FutureProtocol where Base.Output: _ResultConvertible {
        public typealias SuccessHandler = (Base.Output.Success) -> Output
        public typealias FailureHandler = (Base.Output.Failure) -> Output

        case pending(Base, SuccessHandler, FailureHandler)
        case done

        @inlinable
        public init(base: Base, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
            self = .pending(base, success, failure)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let success, let failure):
                switch base.poll(&context) {
                case .ready(let result):
                    self = .done
                    return .ready(result._makeResult().match(success: success, failure: failure))

                case .pending:
                    self = .pending(base, success, failure)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
