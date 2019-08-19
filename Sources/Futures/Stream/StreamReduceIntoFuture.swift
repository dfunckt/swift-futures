//
//  StreamReduceIntoFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum ReduceInto<Output, Base: StreamProtocol>: FutureProtocol {
        public typealias Reduce = (inout Output, Base.Output) -> Void

        case pending(Base, Output, Reduce)
        case done

        @inlinable
        public init(base: Base, state: Output, reducer: @escaping Reduce) {
            self = .pending(base, state, reducer)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, var state, let reducer):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        reducer(&state, output)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(state)
                    case .pending:
                        self = .pending(base, state, reducer)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}

extension Stream._Private.ReduceInto where Output == [Base.Output] {
    @inlinable
    public init(collectingOutputFrom base: Base) {
        self = .pending(base, []) { $0.append($1) }
    }
}
