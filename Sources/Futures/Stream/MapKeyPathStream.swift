//
//  MapKeyPathStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum MapKeyPath<Output, Base: StreamProtocol>: StreamProtocol {
        public typealias Selector = KeyPath<Base.Output, Output>

        case pending(Base, Selector)
        case done

        @inlinable
        public init(base: Base, keyPath: Selector) {
            self = .pending(base, keyPath)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let keyPath):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, keyPath)
                    return .ready(output[keyPath: keyPath])

                case .ready(.none):
                    self = .done
                    return .ready(nil)

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
