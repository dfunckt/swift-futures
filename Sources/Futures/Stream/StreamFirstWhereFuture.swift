//
//  StreamFirstWhereFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum FirstWhere<Base: StreamProtocol> {
        public typealias Predicate = (Base.Output) -> Bool

        case pending(Base, Predicate)
        case done

        @inlinable
        public init(base: Base, predicate: @escaping Predicate) {
            self = .pending(base, predicate)
        }
    }
}

extension Stream._Private.FirstWhere: FutureProtocol {
    public typealias Output = Base.Output?

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .pending(var base, let predicate):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    if predicate(output) {
                        self = .done
                        return .ready(output)
                    }
                    continue

                case .ready(.none):
                    self = .done
                    return .ready(nil)

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
