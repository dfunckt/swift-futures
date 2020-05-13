//
//  StreamAllSatisfyFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum AllSatisfy<Base: StreamProtocol> {
        public typealias Predicate = (Base.Output) -> Bool

        case pending(Base, Predicate)
        case done

        @inlinable
        public init(base: Base, predicate: @escaping Predicate) {
            self = .pending(base, predicate)
        }
    }
}

extension Stream._Private.AllSatisfy: FutureProtocol {
    public typealias Output = Bool

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .pending(var base, let predicate):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    if predicate(output) {
                        continue
                    }
                    self = .pending(base, predicate)
                    return .ready(false)

                case .ready(.none):
                    self = .done
                    return .ready(true)

                case .pending:
                    self = .pending(base, predicate)
                    return .pending
                }
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
