//
//  CollectSink.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Sink._Private {
    public final class Collect<Item>: SinkProtocol {
        public typealias Output = Result<Void, Sink.Completion<Never>>

        @usableFromInline var _elements = [Item]()

        @inlinable
        public var elements: [Item] {
            return _elements
        }

        @inlinable
        public init() {}

        @inlinable
        public init<S: Sequence>(initialElements: S) where S.Element == Item {
            _elements.append(contentsOf: initialElements)
        }

        @inlinable
        public func pollSend(_: inout Context, _ item: Item) -> Poll<Output> {
            _elements.append(item)
            return .ready(.success(()))
        }

        @inlinable
        public func pollFlush(_: inout Context) -> Poll<Output> {
            return .ready(.success(()))
        }

        @inlinable
        public func pollClose(_: inout Context) -> Poll<Output> {
            return .ready(.success(()))
        }
    }
}
