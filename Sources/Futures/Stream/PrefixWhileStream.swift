//
//  PrefixWhileStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum PrefixWhile<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output
        public typealias Predicate = (Base.Output) -> Bool

        case pending(Base, Predicate)
        case done

        @inlinable
        public init(base: Base, predicate: @escaping Predicate) {
            self = .pending(base, predicate)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let predicate):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        if predicate(output) {
                            self = .pending(base, predicate)
                            return .ready(output)
                        }
                        self = .done
                        return .ready(nil)

                    case .ready(.none):
                        self = .done
                        return .ready(nil)

                    case .pending:
                        self = .pending(base, predicate)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
