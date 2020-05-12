//
//  CatchErrorFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum CatchError<U: FutureConvertible, Failure, Base: FutureProtocol> where Base.Output == Result<U.FutureType.Output, Failure> {
        public typealias ErrorHandler = (Failure) -> U

        case pending(Base, ErrorHandler)
        case waiting(U.FutureType)
        case done

        @inlinable
        public init(base: Base, errorHandler: @escaping ErrorHandler) {
            self = .pending(base, errorHandler)
        }
    }
}

extension Future._Private.CatchError: FutureProtocol {
    public typealias Output = U.FutureType.Output

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        while true {
            switch self {
            case .pending(var base, let errorHandler):
                switch base.poll(&context) {
                case .ready(let output):
                    switch output {
                    case .success(let output):
                        self = .done
                        return .ready(output)
                    case .failure(let error):
                        let f = errorHandler(error)
                        self = .waiting(f.makeFuture())
                        continue
                    }
                case .pending:
                    self = .pending(base, errorHandler)
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
