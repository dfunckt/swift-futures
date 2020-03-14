//
//  BlockingSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Blocking<E: BlockingExecutor, Base: SinkProtocol> {
        public typealias Output = Result<Void, Sink.Completion<Base.Failure>>

        @usableFromInline let _base: Box<Base>
        @usableFromInline let _executor: E

        @inlinable
        public init(base: Base, executor: E) {
            _base = .init(base)
            _executor = executor
        }

        @inlinable
        public mutating func send(_ item: Base.Input) -> Output {
            let f = _base.value.send(item)
            return _executor.runUntil(f).map {
                _base.value = $0
            }
        }

        @inlinable
        public mutating func flush() -> Output {
            let f = _base.value.flush()
            return _executor.runUntil(f).map {
                _base.value = $0
            }
        }

        @inlinable
        public mutating func close() -> Output {
            let f = _base.value.close()
            return _executor.runUntil(f).map {
                _base.value = $0
            }
        }
    }
}
