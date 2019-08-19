//
//  FlattenFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Flatten<Base: FutureProtocol>: FutureProtocol where Base.Output: FutureConvertible {
        public typealias Output = Base.Output.FutureType.Output

        case pending(Base)
        case waiting(Base.Output.FutureType)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var base):
                    switch base.poll(&context) {
                    case .ready(let output):
                        let future = output.makeFuture()
                        self = .waiting(future)
                        continue
                    case .pending:
                        self = .pending(base)
                        return .pending
                    }

                case .waiting(var future):
                    switch future.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready(output)
                    case .pending:
                        self = .waiting(future)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
