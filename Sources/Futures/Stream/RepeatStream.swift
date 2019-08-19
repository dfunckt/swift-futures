//
//  RepeatStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Repeat<Output>: StreamProtocol {
        @usableFromInline let _element: Output

        @inlinable
        public init(element: Output) {
            _element = element
        }

        @inlinable
        public func pollNext(_: inout Context) -> Poll<Output?> {
            return .ready(_element)
        }
    }
}
