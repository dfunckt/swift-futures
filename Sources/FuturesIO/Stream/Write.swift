//
//  Write.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

extension Future.IO._Private {
    public struct Write<Base: OutputStream> {
        @usableFromInline var _base: Base
        @usableFromInline let _buffer: IOBufferPointer

        @inlinable
        public init(base: Base, buffer: IOBufferPointer) {
            _base = base
            _buffer = buffer
        }
    }
}

extension Future.IO._Private.Write: FutureProtocol {
    public typealias Output = IOResult<Int>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        return _base.pollWrite(&context, from: _buffer)
    }
}
