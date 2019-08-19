//
//  MapResultStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct MapResult<Success, Failure, Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible, Failure: Error {
        public typealias Output = Result<Success, Failure>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _base.pollNext(&context)
        }
    }
}

extension Stream._Private.MapResult where Failure == Base.Output.Failure {
    @inlinable
    public init(base: Base, success: @escaping (Base.Output.Success) -> Success) {
        _base = .init(base: base) {
            $0._makeResult().map(success)
        }
    }
}

extension Stream._Private.MapResult where Success == Base.Output.Success {
    @inlinable
    public init(base: Base, failure: @escaping (Base.Output.Failure) -> Failure) {
        _base = .init(base: base) {
            $0._makeResult().mapError(failure)
        }
    }
}
