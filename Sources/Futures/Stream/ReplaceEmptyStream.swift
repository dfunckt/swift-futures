//
//  ReplaceEmptyStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum ReplaceEmpty<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base, Output)
        case notEmpty(Base)
        case complete
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
                case .ready(.some(let output)):
                    self = .notEmpty(base)
                    return .ready(output)
                case .ready(.none):
                    self = .complete
                    return .ready(output)
                case .pending:
                    self = .pending(base, output)
                    return .pending
                }

            case .notEmpty(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .notEmpty(base)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .notEmpty(base)
                    return .pending
                }

            case .complete:
                self = .done
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
