//
//  StreamFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Future<Base: StreamProtocol>: FutureProtocol {
        public typealias Output = (output: Base.Output?, stream: Base)

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
                case .ready(let output):
                    self = .done
                    return .ready((output, base))
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
