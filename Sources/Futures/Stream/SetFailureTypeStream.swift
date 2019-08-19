//
//  SetFailureTypeStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct SetFailureType<Success, Failure: Error, Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Result<Success, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}

extension Stream._Private.SetFailureType where Base.Output == Success {
    @inlinable
    public init(base: Base) {
        _base = .init(base: base) {
            .success($0)
        }
    }
}

extension Stream._Private.SetFailureType where Base.Output: _ResultConvertible, Base.Output.Success == Success, Base.Output.Failure == Never {
    @inlinable
    public init(base: Base) {
        _base = .init(base: base) {
            // swiftlint:disable:next force_cast
            $0._makeResult().mapError { $0 as! Failure }
        }
    }
}
