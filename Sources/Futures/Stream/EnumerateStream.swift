//
//  EnumerateStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Enumerate<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = (offset: Int, output: Base.Output)

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base) {
            var offset = 0
            _base = .init(base: base) {
                defer { offset += 1 }
                return (offset, $0)
            }
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}
