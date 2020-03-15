//
//  BlockingSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Blocking<Base: SinkProtocol> {
        public typealias Output = Result<Void, Sink.Completion<Base.Failure>>

        @usableFromInline let _base: Box<Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base)
        }

        @inlinable
        public mutating func send(_ item: Base.Input) -> Output {
            var f = _base.value.send(item)
            return ThreadExecutor.current.run(until: &f).map {
                _base.value = $0
            }
        }

        @inlinable
        public mutating func flush() -> Output {
            var f = _base.value.flush()
            return ThreadExecutor.current.run(until: &f).map {
                _base.value = $0
            }
        }

        @inlinable
        public mutating func close() -> Output {
            var f = _base.value.close()
            return ThreadExecutor.current.run(until: &f).map {
                _base.value = $0
            }
        }
    }
}
