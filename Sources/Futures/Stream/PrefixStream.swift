//
//  PrefixStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Prefix<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base, Int, Int)
        case done

        @inlinable
        public init(base: Base, maxLength: Int) {
            self = .pending(base, 0, maxLength)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let index, let maxLength):
                if index == maxLength {
                    self = .done
                    return .ready(nil)
                }
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, index + 1, maxLength)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pending(base, index, maxLength)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
