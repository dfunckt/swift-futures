//
//  PeekFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Peek<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output
        public typealias Body = (Base.Output) -> Void

        case pending(Base, Body)
        case done

        @inlinable
        public init(base: Base, body: @escaping Body) {
            self = .pending(base, body)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let inspect):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    inspect(output)
                    return .ready(output)

                case .pending:
                    self = .pending(base, inspect)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
