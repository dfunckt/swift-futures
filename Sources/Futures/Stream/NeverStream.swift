//
//  NeverStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Never<Output>: StreamProtocol {
        @inlinable
        public init() {}

        @inlinable
        public mutating func pollNext(_: inout Context) -> Poll<Output?> {
            return .pending
        }
    }
}
