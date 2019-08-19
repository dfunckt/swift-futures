//
//  StreamLastWhereFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum LastWhere<Base: StreamProtocol>: FutureProtocol {
        public typealias Output = Base.Output?
        public typealias Predicate = (Base.Output) -> Bool

        case pending(Base, Predicate)
        case flushing(Base, Predicate, Base.Output)
        case done

        @inlinable
        public init(base: Base, predicate: @escaping Predicate) {
            self = .pending(base, predicate)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var base, let predicate):
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        if predicate(output) {
                            self = .flushing(base, predicate, output)
                            continue
                        }
                        self = .done
                        return .ready(nil)
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(base, predicate)
                        return .pending
                    }

                case .flushing(var base, let predicate, var lastOutput):
                    while true {
                        switch base.pollNext(&context) {
                        case .ready(.some(let output)):
                            if predicate(output) {
                                lastOutput = output
                            }
                            continue
                        case .ready(.none):
                            self = .done
                            return .ready(lastOutput)
                        case .pending:
                            self = .flushing(base, predicate, lastOutput)
                            return .pending
                        }
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
