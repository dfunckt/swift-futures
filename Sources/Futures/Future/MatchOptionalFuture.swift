//
//  MatchOptionalFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct MatchOptional<Output, Wrapped, Base: FutureProtocol>: FutureProtocol where Base.Output == Wrapped? {
        public typealias SomeHandler = (Wrapped) -> Output
        public typealias NoneHandler = () -> Output

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, some: @escaping SomeHandler, none: @escaping NoneHandler) {
            _base = .init(base: base) {
                $0.match(some: some, none: none)
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
