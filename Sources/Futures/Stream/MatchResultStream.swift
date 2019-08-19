//
//  MatchResultStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum MatchResult<Output, Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible {
        public typealias SuccessHandler = (Base.Output.Success) -> Output
        public typealias FailureHandler = (Base.Output.Failure) -> Output

        case pending(Base, SuccessHandler, FailureHandler)
        case done

        @inlinable
        public init(base: Base, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
            self = .pending(base, success, failure)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let success, let failure):
                switch base.pollNext(&context) {
                case .ready(.some(let result)):
                    self = .pending(base, success, failure)
                    return .ready(result._makeResult().match(success: success, failure: failure))

                case .ready(.none):
                    self = .done
                    return .ready(nil)

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
