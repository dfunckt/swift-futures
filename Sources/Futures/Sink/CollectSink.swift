//
//  CollectSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public final class Collect<Item> {
        @usableFromInline var _elements = [Item]()

        @inlinable
        public init() {}

        @inlinable
        public init<S: Sequence>(initialElements: S) where S.Element == Item {
            _elements.append(contentsOf: initialElements)
        }
    }
}

extension Sink._Private.Collect: SinkProtocol {
    public typealias Input = Item
    public typealias Failure = Never

    @inlinable
    public var elements: [Item] {
        return _elements
    }

    @inlinable
    public func pollSend(_: inout Context, _ item: Input) -> PollSink<Failure> {
        _elements.append(item)
        return .ready(.success(()))
    }

    @inlinable
    public func pollFlush(_: inout Context) -> PollSink<Failure> {
        return .ready(.success(()))
    }

    @inlinable
    public func pollClose(_: inout Context) -> PollSink<Failure> {
        return .ready(.success(()))
    }
}
