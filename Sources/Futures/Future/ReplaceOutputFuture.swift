//
//  ReplaceOutputFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct ReplaceOutput<Output, Base: FutureProtocol>: FutureProtocol {
        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, output: Output) {
            _base = .init(base: base) {
                _ in output
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
