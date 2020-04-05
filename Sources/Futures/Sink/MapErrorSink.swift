//
//  MapErrorSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct MapError<Failure: Error, Base: SinkProtocol>: SinkProtocol {
        public typealias Input = Base.Input

        public typealias Adapt = (Base.Failure) -> Failure

        @usableFromInline var _base: Base
        @usableFromInline let _adapt: Adapt

        @inlinable
        public init(base: Base, adapt: @escaping Adapt) {
            _base = base
            _adapt = adapt
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
            return _base.pollSend(&context, item).mapError {
                .failure(.failure(_adapt($0)))
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
            return _base.pollFlush(&context).mapError {
                .failure(.failure(_adapt($0)))
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
            return _base.pollClose(&context).mapError {
                .failure(.failure(_adapt($0)))
            }
        }
    }
}
