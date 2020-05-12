//
//  AssertNoErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct AssertNoError<Output, Failure, Base: StreamProtocol>: StreamProtocol where Base.Output == Result<Output, Failure> {
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
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}
