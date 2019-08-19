//
//  StreamContainsFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Contains<Base: StreamProtocol>: FutureProtocol where Base.Output: Equatable {
        public typealias Output = Bool

        case pending(Base, Base.Output)
        case done

        @inlinable
        public init(base: Base, output: Base.Output) {
            self = .pending(base, output)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let output):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let result)):
                        if output == result {
                            self = .done
                            return .ready(true)
                        }
                        continue

                    case .ready(.none):
                        self = .done
                        return .ready(false)

                    case .pending:
                        self = .pending(base, output)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
