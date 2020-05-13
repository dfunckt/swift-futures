//
//  AbortStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Abort<U: FutureConvertible, Base: StreamProtocol> where U.FutureType.Output == Void {
        public typealias Signal = () -> U

        case pending(Base, Signal)
        case polling(Base, U.FutureType)
        case done
    }
}

extension Stream._Private.Abort: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public init(base: Base, signal: @escaping Signal) {
        self = .pending(base, signal)
    }

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
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
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(base, future)
                        return .ready(output)
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
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
