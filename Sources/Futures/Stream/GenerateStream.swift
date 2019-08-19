//
//  GenerateStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Generate<Output>: StreamProtocol {
        public typealias Generator = (Output) -> Output?

        case initial(Generator, Output)
        case pending(Generator, Output)
        case done

        @inlinable
        public init(first: Output, next: @escaping Generator) {
            self = .initial(next, first)
        }

        @inlinable
        public mutating func pollNext(_: inout Context) -> Poll<Output?> {
            switch self {
            case .initial(let next, let output):
                self = .pending(next, output)
                return .ready(output)

            case .pending(let next, let previousOutput):
                if let output = next(previousOutput) {
                    self = .pending(next, output)
                    return .ready(output)
                }
                self = .done
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
