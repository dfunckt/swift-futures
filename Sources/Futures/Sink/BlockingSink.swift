//
//  BlockingSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public struct Blocking<Base: SinkProtocol> {
        @usableFromInline let _base: Box<Base>

        @inlinable
        public init(base: Base) {
            _base = .init(base)
        }
    }
}

extension Sink._Private.Blocking {
    @inlinable
    public mutating func send(_ item: Base.Input) -> SinkResult<Base.Failure> {
        var f = _base.value.send(item)
        return ThreadExecutor.current.run(until: &f).map {
            _base.value = $0
        }
    }

    @inlinable
    public mutating func flush() -> SinkResult<Base.Failure> {
        var f = _base.value.flush()
        return ThreadExecutor.current.run(until: &f).map {
            _base.value = $0
        }
    }

    @inlinable
    public mutating func close() -> SinkResult<Base.Failure> {
        var f = _base.value.close()
        return ThreadExecutor.current.run(until: &f).map {
            _base.value = $0
        }
    }
}
