//
//  MatchEitherFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum MatchEither<Output, Base: FutureProtocol>: FutureProtocol where Base.Output: EitherConvertible {
        public typealias LeftHandler = (Base.Output.Left) -> Output
        public typealias RightHandler = (Base.Output.Right) -> Output

        case pending(Base, LeftHandler, RightHandler)
        case done

        @inlinable
        public init(base: Base, left: @escaping LeftHandler, right: @escaping RightHandler) {
            self = .pending(base, left, right)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let left, let right):
                switch base.poll(&context) {
                case .ready(let result):
                    self = .done
                    return .ready(result.makeEither().match(left: left, right: right))

                case .pending:
                    self = .pending(base, left, right)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
