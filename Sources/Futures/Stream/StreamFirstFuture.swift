//
//  StreamFirstFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum First<Base: StreamProtocol>: FutureProtocol {
        public typealias Output = Base.Output?

        case pending(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base):
                switch base.pollNext(&context) {
                case .ready(let result):
                    self = .done
                    return .ready(result)
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
