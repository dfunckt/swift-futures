//
//  FlattenStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Flatten<Base: StreamProtocol>: StreamProtocol where Base.Output: StreamConvertible {
        public typealias Output = Base.Output.StreamType.Output

        @usableFromInline var _base: FlatMap<Base.Output, Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base: base) {
                $0.makeStream()
            }
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}
