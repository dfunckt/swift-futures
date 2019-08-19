//
//  OptionalStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    // swiftformat:disable:next typeSugar
    public enum Optional<Wrapped>: StreamProtocol {
        // swiftlint:disable:previous syntactic_sugar
        case some(Wrapped)
        case none
        case done

        @inlinable
        public init(value: Wrapped?) {
            switch value {
            case .some(let value):
                self = .some(value)
            case .none:
                self = .none
            }
        }

        @inlinable
        public mutating func pollNext(_: inout Context) -> Poll<Wrapped?> {
            switch self {
            case .some(let value):
                self = .none
                return .ready(value)
            case .none:
                self = .done
                return .ready(nil)
            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
