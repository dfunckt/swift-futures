//
//  MapKeyPathFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum MapKeyPath<Output, Base: FutureProtocol>: FutureProtocol {
        public typealias Selector = KeyPath<Base.Output, Output>

        case pending(Base, Selector)
        case done

        @inlinable
        public init(base: Base, keyPath: Selector) {
            self = .pending(base, keyPath)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let keyPath):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    return .ready(output[keyPath: keyPath])

                case .pending:
                    self = .pending(base, keyPath)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
