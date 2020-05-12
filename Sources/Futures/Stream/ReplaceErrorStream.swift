//
//  ReplaceErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct ReplaceError<Output, Failure, Base: StreamProtocol>: StreamProtocol where Base.Output == Result<Output, Failure> {
        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, output: Output) {
            _base = .init(base: base) {
                $0.match(
                    success: { $0 },
                    failure: { _ in output }
                )
            }
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}
