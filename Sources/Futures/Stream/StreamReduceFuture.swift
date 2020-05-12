//
//  StreamReduceFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Reduce<Output, Base: StreamProtocol>: FutureProtocol {
        public typealias Accumulate = (Output, Base.Output) -> Output

        case pending(Base, Output, Accumulate)
        case done

        @inlinable
        public init(base: Base, initialResult: Output, nextPartialResult: @escaping Accumulate) {
            self = .pending(base, initialResult, nextPartialResult)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, var previousOutput, let accumulate):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        previousOutput = accumulate(previousOutput, output)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(previousOutput)
                    case .pending:
                        self = .pending(base, previousOutput, accumulate)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}

extension Stream._Private.Reduce {
    @inlinable
    public init(replacingOutputFrom base: Base, with output: Output) {
        self = .pending(base, output) { o, _ in o }
    }
}

extension Stream._Private.Reduce where Output == Int {
    @inlinable
    public init(countingElementsFrom base: Base) {
        self = .pending(base, 0) { count, _ in count + 1 }
    }
}
