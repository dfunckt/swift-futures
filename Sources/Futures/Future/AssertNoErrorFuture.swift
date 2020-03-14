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
            let prefix = prefix.isEmpty ? "" : "\(prefix): "
            _base = .init(base: base) {
                switch $0 {
                case .success(let output):
                    return output
                case .failure(let error):
                    preconditionFailure("\(prefix)\(error)", file: file, line: line)
                }
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
