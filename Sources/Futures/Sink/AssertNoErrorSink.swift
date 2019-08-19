//
//  AssertNoErrorSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct AssertNoError<Base: SinkProtocol>: SinkProtocol {
        public typealias Input = Base.Input
        public typealias Output = Result<Void, Sink.Completion<Never>>

        @usableFromInline var _base: Base
        @usableFromInline var _message: String

        @inlinable
        public init(base: Base, prefix: String, file: StaticString, line: UInt) {
            _base = base
            if prefix.isEmpty {
                _message = "Unexpected result at \(file):\(line)"
            } else {
                _message = "\(prefix) Unexpected result at \(file):\(line)"
            }
        }

        @inlinable
        public mutating func pollSend(_ context: inout Context, _ item: Input) -> Poll<Output> {
            return _base.pollSend(&context, item).map {
                $0.mapError {
                    $0.mapError {
                        fatalError("\(_message): \($0)")
                    }
                }
            }
        }

        @inlinable
        public mutating func pollFlush(_ context: inout Context) -> Poll<Output> {
            return _base.pollFlush(&context).map {
                $0.mapError {
                    $0.mapError {
                        fatalError("\(_message): \($0)")
                    }
                }
            }
        }

        @inlinable
        public mutating func pollClose(_ context: inout Context) -> Poll<Output> {
            return _base.pollClose(&context).map {
                $0.mapError {
                    $0.mapError {
                        fatalError("\(_message): \($0)")
                    }
                }
            }
        }
    }
}
