//
//  FlattenFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct Flatten<Base: FutureProtocol>: FutureProtocol where Base.Output: FutureConvertible {
        public typealias Output = Base.Output.FutureType.Output

        @usableFromInline var _base: FlatMap<Base.Output, Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base: base) {
                $0.makeFuture()
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
