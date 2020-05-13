//
//  SetFailureTypeSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct SetFailureType<Failure: Error, Base: SinkProtocol> where Base.Failure == Never {
        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }
    }
}

extension Sink._Private.SetFailureType: SinkProtocol {
    public typealias Input = Base.Input

    @inlinable
    public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
        return _base.pollSend(&context, item).mapError {
            .failure(.failure($0 as! Failure)) // swiftlint:disable:this force_cast
        }
    }

    @inlinable
    public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
        return _base.pollFlush(&context).mapError {
            .failure(.failure($0 as! Failure)) // swiftlint:disable:this force_cast
        }
    }

    @inlinable
    public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
        return _base.pollClose(&context).mapError {
            .failure(.failure($0 as! Failure)) // swiftlint:disable:this force_cast
        }
    }
}
