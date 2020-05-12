//
//  AssertNoErrorFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct AssertNoError<Output, Failure, Base: FutureProtocol>: FutureProtocol where Base.Output == Result<Output, Failure> {
        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, prefix: String, file: StaticString, line: UInt) {
            let message: String
            if prefix.isEmpty {
                message = "Unexpected error at \(file):\(line)"
            } else {
                message = "\(prefix) Unexpected error at \(file):\(line)"
            }
            _base = .init(base: base) {
                switch $0 {
                case .success(let output):
                    return output
                case .failure(let error):
                    fatalError("\(message): \(error)")
                }
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
