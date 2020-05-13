//
//  FlatMapFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum FlatMap<U: FutureConvertible, Base: FutureProtocol> {
        public typealias Transform = (Base.Output) -> U

        case pending(Base, Transform)
        case waiting(U.FutureType)
        case done

        @inlinable
        public init(base: Base, transform: @escaping Transform) {
            self = .pending(base, transform)
        }
    }
}

extension Future._Private.FlatMap: FutureProtocol {
    public typealias Output = U.FutureType.Output

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch self {
            case .pending(var base, let transform):
                switch base.poll(&context) {
                case .ready(let output):
                    let future = transform(output).makeFuture()
                    self = .waiting(future)
                    continue
                case .pending:
                    self = .pending(base, transform)
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
