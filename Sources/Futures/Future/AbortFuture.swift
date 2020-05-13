//
//  AbortFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Abort<U: FutureConvertible, Base: FutureProtocol> where U.FutureType.Output == Void {
        public typealias Signal = () -> U

        case pending(Base, Signal)
        case polling(Base, U.FutureType)
        case done

        @inlinable
        public init(base: Base, signal: @escaping Signal) {
            self = .pending(base, signal)
        }
    }
}

extension Future._Private.Abort: FutureProtocol {
    public typealias Output = Base.Output?

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch self {
            case .pending(let base, let signal):
                let future = signal().makeFuture()
                self = .polling(base, future)
                continue

            case .polling(var base, var future):
                switch future.poll(&context) {
                case .ready:
                    self = .done
                    return .ready(nil)
                case .pending:
                    switch base.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready(output)
                    case .pending:
                        self = .polling(base, future)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
