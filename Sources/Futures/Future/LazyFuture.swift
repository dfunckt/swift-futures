//
//  LazyFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Lazy<U: FutureConvertible>: FutureProtocol {
        public typealias Output = U.FutureType.Output
        public typealias Constructor = () -> U

        case pending(Constructor)
        case waiting(U.FutureType)
        case done

        @inlinable
        public init(_ body: @escaping Constructor) {
            self = .pending(body)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(let constructor):
                    let f = constructor()
                    self = .waiting(f.makeFuture())
                    continue

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
