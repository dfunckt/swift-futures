//
//  ReferenceFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public final class Reference<Base: FutureProtocol>: FutureProtocol {
        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }

        @inlinable
        public func poll(_ context: inout Context) -> Poll<Base.Output> {
            return _base.poll(&context)
        }
    }
}
