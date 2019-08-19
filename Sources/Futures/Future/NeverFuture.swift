//
//  NeverFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct Never<Output>: FutureProtocol {
        @inlinable
        public init() {}

        @inlinable
        public func poll(_: inout Context) -> Poll<Output> {
            return .pending
        }
    }
}
