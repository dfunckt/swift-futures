//
//  PeekFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct Peek<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, inspect: @escaping (Base.Output) -> Void) {
            _base = .init(base: base) {
                inspect($0)
                return $0
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
