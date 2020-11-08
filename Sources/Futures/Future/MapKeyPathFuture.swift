//
//  MapKeyPathFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct MapKeyPath<Output, Base: FutureProtocol>: FutureProtocol {
        public typealias Selector = KeyPath<Base.Output, Output>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, keyPath: Selector) {
            _base = .init(base: base) {
                $0[keyPath: keyPath]
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}

extension Future._Private {
    public struct MapKeyPath2<Output0, Output1, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = (Output0, Output1)
        public typealias Selector<T> = KeyPath<Base.Output, T>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, keyPath0: Selector<Output0>, keyPath1: Selector<Output1>) {
            _base = .init(base: base) {
                return (
                    $0[keyPath: keyPath0],
                    $0[keyPath: keyPath1]
                )
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}

extension Future._Private {
    public struct MapKeyPath3<Output0, Output1, Output2, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = (Output0, Output1, Output2)
        public typealias Selector<T> = KeyPath<Base.Output, T>

        @usableFromInline var _base: Map<Output, Base>

        @inlinable
        public init(base: Base, keyPath0: Selector<Output0>, keyPath1: Selector<Output1>, keyPath2: Selector<Output2>) {
            _base = .init(base: base) {
                return (
                    $0[keyPath: keyPath0],
                    $0[keyPath: keyPath1],
                    $0[keyPath: keyPath2]
                )
            }
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            return _base.poll(&context)
        }
    }
}
