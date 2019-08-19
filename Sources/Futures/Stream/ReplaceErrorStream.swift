//
//  ReplaceErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum ReplaceError<Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible {
        public typealias Output = Base.Output.Success

        case pending(Base, Output)
        case done

        @inlinable
        public init(base: Base, output: Output) {
            self = .pending(base, output)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let output):
                switch base.pollNext(&context) {
                case .ready(.some(let result)):
                    self = .pending(base, output)
                    let result = result._makeResult().match(
                        success: { $0 },
                        failure: { _ in output }
                    )
                    return .ready(result)

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, output)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
