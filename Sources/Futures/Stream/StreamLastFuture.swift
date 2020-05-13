//
//  StreamLastFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Last<Base: StreamProtocol> {
        case pending(Base)
        case flushing(Base, Base.Output)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }
    }
}

extension Stream._Private.Last: FutureProtocol {
    public typealias Output = Base.Output?

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch self {
            case .pending(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .flushing(base, output)
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pending(base)
                    return .pending
                }

            case .flushing(var base, var lastOutput):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        lastOutput = output
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(lastOutput)
                    case .pending:
                        self = .flushing(base, lastOutput)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
