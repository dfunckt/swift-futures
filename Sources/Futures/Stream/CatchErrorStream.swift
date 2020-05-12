//
//  CatchErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum CatchError<U: StreamConvertible, Failure, Base: StreamProtocol> where Base.Output == Result<U.StreamType.Output, Failure> {
        public typealias ErrorHandler = (Failure) -> U

        case pending(Base, ErrorHandler)
        case waiting(Base, ErrorHandler, U.StreamType)
        case done

        @inlinable
        public init(base: Base, errorHandler: @escaping ErrorHandler) {
            self = .pending(base, errorHandler)
        }
    }
}

extension Stream._Private.CatchError: StreamProtocol {
    public typealias Output = U.StreamType.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .pending(var base, let errorHandler):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    switch output {
                    case .success(let output):
                        self = .pending(base, errorHandler)
                        return .ready(output)
                    case .failure(let error):
                        let f = errorHandler(error)
                        self = .waiting(base, errorHandler, f.makeStream())
                        continue
                    }
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pending(base, errorHandler)
                    return .pending
                }

            case .waiting(let base, let errorHandler, var stream):
                switch stream.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .waiting(base, errorHandler, stream)
                    return .ready(output)
                case .ready(.none):
                    self = .pending(base, errorHandler)
                    continue
                case .pending:
                    self = .waiting(base, errorHandler, stream)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
