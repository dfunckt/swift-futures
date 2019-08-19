//
//  CatchErrorFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum CatchError<U: FutureConvertible, Base: FutureProtocol>: FutureProtocol where Base.Output: _ResultConvertible, Base.Output.Success == U.FutureType.Output {
        public typealias Output = Base.Output.Success
        public typealias ErrorHandler = (Base.Output.Failure) -> U

        case pending(Base, ErrorHandler)
        case waiting(U.FutureType)
        case done

        @inlinable
        public init(base: Base, errorHandler: @escaping ErrorHandler) {
            self = .pending(base, errorHandler)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var base, let errorHandler):
                    switch base.poll(&context) {
                    case .ready(let output):
                        switch output._makeResult() {
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
}
