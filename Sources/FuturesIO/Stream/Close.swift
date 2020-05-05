//
//  Close.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

extension Future.IO._Private {
    public struct Close<Base: OutputStream> {
        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }
    }
}

extension Future.IO._Private.Close: FutureProtocol {
    public typealias Output = IOResult<Void>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        return _base.pollClose(&context)
    }
}
