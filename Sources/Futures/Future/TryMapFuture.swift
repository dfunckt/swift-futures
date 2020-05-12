//
//  TryMapFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct TryMap<T, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Result<T, Error>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, catching block: @escaping (Base.Output) throws -> T) {
            _base = .init(base: base) {
                do {
                    return try .success(block($0))
                } catch {
                    return .failure(error)
                }
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
