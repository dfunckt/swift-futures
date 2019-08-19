//
//  ReadyFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Ready<Output>: FutureProtocol {
        case pending(Output)
        case done

        @inlinable
        public init(output: Output) {
            self = .pending(output)
        }

        @inlinable
        public mutating func poll(_: inout Context) -> Poll<Output> {
            switch self {
            case .pending(let output):
                self = .done
                return .ready(output)
            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}

extension Future._Private.Ready where Output == Void {
    @inlinable
    public init() {
        self = .pending(())
    }
}
