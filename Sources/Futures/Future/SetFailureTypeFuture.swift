//
//  SetFailureTypeFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct SetFailureType<Success, Failure: Error, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Result<Success, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}

extension Future._Private.SetFailureType where Base.Output == Success {
    @inlinable
    public init(base: Base) {
        _base = .init(base: base) {
            .success($0)
        }
    }
}

extension Future._Private.SetFailureType where Base.Output == Result<Success, Never> {
    @inlinable
    public init(base: Base) {
        _base = .init(base: base) {
            // swiftlint:disable:next force_cast
            $0.mapError { $0 as! Failure }
        }
    }
}
