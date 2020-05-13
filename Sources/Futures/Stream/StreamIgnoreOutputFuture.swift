//
//  StreamIgnoreOutputFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum IgnoreOutput<Base: StreamProtocol> {
        case pending(Base)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }
    }
}

extension Stream._Private.IgnoreOutput: FutureProtocol {
    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Void> {
        switch self {
        case .pending(var base):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some):
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(())
                case .pending:
                    self = .pending(base)
                    return .pending
                }
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
