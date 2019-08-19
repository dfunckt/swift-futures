//
//  FlattenResultStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum FlattenResult<Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible, Base.Output.Success: _ResultConvertible, Base.Output.Failure == Base.Output.Success.Failure {
        public typealias Output = Result<Base.Output.Success.Success, Base.Output.Failure>

        case pending(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let result)):
                    self = .pending(base)
                    return .ready(result._makeResult().flatten())

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
