//
//  AssertNoErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum AssertNoError<Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible {
        public typealias Output = Base.Output.Success

        case pending(Base, String)
        case done

        @inlinable
        public init(base: Base, prefix: String, file: StaticString, line: UInt) {
            let message: String
            if prefix.isEmpty {
                message = "Unexpected error at \(file):\(line)"
            } else {
                message = "\(prefix) Unexpected error at \(file):\(line)"
            }
            self = .pending(base, message)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let message):
                switch base.pollNext(&context) {
                case .ready(.some(let result)):
                    switch result._makeResult() {
                    case .success(let output):
                        self = .pending(base, message)
                        return .ready(output)
                    case .failure(let error):
                        fatalError("\(message): \(error)")
                    }

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, message)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
