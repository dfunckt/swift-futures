//
//  AssertNoErrorSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct AssertNoError<Base: SinkProtocol> {
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
    }
}

extension Sink._Private.AssertNoError: SinkProtocol {
    public typealias Input = Base.Input
    public typealias Failure = Never

    @inlinable
    public mutating func pollSend(_ context: inout Context, _ item: Input) -> PollSink<Failure> {
        return _base.pollSend(&context, item).mapError {
            fatalError("\(_message): \($0)")
        }
    }

    @inlinable
    public mutating func pollFlush(_ context: inout Context) -> PollSink<Failure> {
        return _base.pollFlush(&context).mapError {
            fatalError("\(_message): \($0)")
        }
    }

    @inlinable
    public mutating func pollClose(_ context: inout Context) -> PollSink<Failure> {
        return _base.pollClose(&context).mapError {
            fatalError("\(_message): \($0)")
        }
    }
}
