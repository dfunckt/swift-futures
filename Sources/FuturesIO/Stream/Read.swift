//
//  Read.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

extension Future.IO._Private {
    public struct Read<Base: InputStream> {
        @usableFromInline var _base: Base
        @usableFromInline let _buffer: IOMutableBufferPointer

        @inlinable
        public init(base: Base, buffer: IOMutableBufferPointer) {
            _base = base
            _buffer = buffer
        }
    }
}

extension Future.IO._Private.Read: FutureProtocol {
    public typealias Output = IOResult<Int>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        return _base.pollRead(&context, into: _buffer)
    }
}
