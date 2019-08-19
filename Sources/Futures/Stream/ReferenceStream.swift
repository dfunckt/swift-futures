//
//  ReferenceStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public final class Reference<Base: StreamProtocol>: StreamProtocol {
        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }

        @inlinable
        public func pollNext(_ context: inout Context) -> Poll<Base.Output?> {
            return _base.pollNext(&context)
        }
    }
}
