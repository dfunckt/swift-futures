//
//  MatchOptionalStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum MatchOptional<Output, Base: StreamProtocol>: StreamProtocol where Base.Output: _OptionalConvertible {
        public typealias SomeHandler = (Base.Output.WrappedType) -> Output
        public typealias NoneHandler = () -> Output

        case pending(Base, SomeHandler, NoneHandler)
        case done

        @inlinable
        public init(base: Base, some: @escaping SomeHandler, none: @escaping NoneHandler) {
            self = .pending(base, some, none)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let some, let none):
                switch base.pollNext(&context) {
                case .ready(.some(let result)):
                    self = .pending(base, some, none)
                    return .ready(result._makeOptional().match(some: some, none: none))

                case .ready(.none):
                    self = .done
                    return .ready(nil)

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
