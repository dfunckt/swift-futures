//
//  IgnoreOutputFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum IgnoreOutput<Base: FutureProtocol> {
        case pending(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }
    }
}

extension Future._Private.IgnoreOutput: FutureProtocol {
    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Void> {
        switch self {
        case .pending(var base):
            switch base.poll(&context) {
            case .ready:
                self = .done
                return .ready
            case .pending:
                self = .pending(base)
                return .pending
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
