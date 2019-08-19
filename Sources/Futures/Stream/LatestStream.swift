//
//  LatestStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Latest<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base)
        case complete
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base):
                var lastOutput: Output?

                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        lastOutput = output
                        continue
                    case .ready(.none):
                        if let output = lastOutput {
                            self = .complete
                            return .ready(output)
                        }
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(base)
                        if let output = lastOutput {
                            return .ready(output)
                        }
                        return .pending
                    }
                }

            case .complete:
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
