//
//  MapResultFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct MapValue<NewSuccess, Success, Failure, Base: FutureProtocol>: FutureProtocol where Base.Output == Result<Success, Failure> {
        public typealias Output = Result<NewSuccess, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, success: @escaping (Success) -> NewSuccess) {
            _base = .init(base: base) {
                $0.map(success)
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}

extension Future._Private {
    public struct MapError<NewFailure, Success, Failure, Base: FutureProtocol>: FutureProtocol where Base.Output == Result<Success, Failure>, NewFailure: Error {
        public typealias Output = Result<Success, NewFailure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, failure: @escaping (Failure) -> NewFailure) {
            _base = .init(base: base) {
                $0.mapError(failure)
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
