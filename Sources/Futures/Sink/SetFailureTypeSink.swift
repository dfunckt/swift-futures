//
//  SetFailureTypeSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct SetFailureType<Failure: Error, Base: SinkProtocol>: SinkProtocol where Base.Failure == Never {
        public typealias Input = Base.Input
        public typealias Output = Result<Void, Sink.Completion<Failure>>

        @usableFromInline var _base: Base

        @inlinable
        public init(base: Base) {
            _base = base
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output> {
            return _base.pollSend(&context, item).map {
                $0.mapError {
                    // swiftlint:disable:next force_cast
                    $0.mapError { $0 as! Failure }
                }
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> Poll<Output> {
            return _base.pollFlush(&context).map {
                $0.mapError {
                    // swiftlint:disable:next force_cast
                    $0.mapError { $0 as! Failure }
                }
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> Poll<Output> {
            return _base.pollClose(&context).map {
                $0.mapError {
                    // swiftlint:disable:next force_cast
                    $0.mapError { $0 as! Failure }
                }
            }
        }
    }
}
