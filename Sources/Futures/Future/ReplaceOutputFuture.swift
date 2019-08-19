//
//  ReplaceOutputFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum ReplaceOutput<Output, Base: FutureProtocol>: FutureProtocol {
        case pending(Base, Output)
        case done

        @inlinable
        public init(base: Base, output: Output) {
            self = .pending(base, output)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let output):
                switch base.poll(&context) {
                case .ready:
                    self = .done
                    return .ready(output)

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
