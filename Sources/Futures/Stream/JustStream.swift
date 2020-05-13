//
//  JustStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Just<Output> {
        case pending(Output)
        case complete
        case done

        @inlinable
        public init(element: Output) {
            self = .pending(element)
        }
    }
}

extension Stream._Private.Just: StreamProtocol {
    @inlinable
    public mutating func pollNext(_: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(let output):
            self = .complete
            return .ready(output)
        case .complete:
            self = .done
            return .ready(nil)
        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
