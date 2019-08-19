//
//  MatchOptionalFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum MatchOptional<Output, Base: FutureProtocol>: FutureProtocol where Base.Output: _OptionalConvertible {
        public typealias SomeHandler = (Base.Output.WrappedType) -> Output
        public typealias NoneHandler = () -> Output

        case pending(Base, SomeHandler, NoneHandler)
        case done

        @inlinable
        public init(base: Base, some: @escaping SomeHandler, none: @escaping NoneHandler) {
            self = .pending(base, some, none)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let some, let none):
                switch base.poll(&context) {
                case .ready(let result):
                    self = .done
                    return .ready(result._makeOptional().match(some: some, none: none))

                case .pending:
                    self = .pending(base, some, none)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
