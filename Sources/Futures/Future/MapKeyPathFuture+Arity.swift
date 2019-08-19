//
//  MapKeyPathFuture+Arity.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum MapKeyPath2<Output0, Output1, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = (Output0, Output1)
        public typealias Selector<T> = KeyPath<Base.Output, T>

        case pending(Base, Selector<Output0>, Selector<Output1>)
        case done

        @inlinable
        public init(base: Base, keyPath0: Selector<Output0>, keyPath1: Selector<Output1>) {
            self = .pending(base, keyPath0, keyPath1)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let keyPath0, let keyPath1):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    return .ready((
                        output[keyPath: keyPath0],
                        output[keyPath: keyPath1]
                    ))

                case .pending:
                    self = .pending(base, keyPath0, keyPath1)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }

    public enum MapKeyPath3<Output0, Output1, Output2, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = (Output0, Output1, Output2)
        public typealias Selector<T> = KeyPath<Base.Output, T>

        case pending(Base, Selector<Output0>, Selector<Output1>, Selector<Output2>)
        case done

        @inlinable
        public init(base: Base, keyPath0: Selector<Output0>, keyPath1: Selector<Output1>, keyPath2: Selector<Output2>) {
            self = .pending(base, keyPath0, keyPath1, keyPath2)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let keyPath0, let keyPath1, let keyPath2):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    return .ready((
                        output[keyPath: keyPath0],
                        output[keyPath: keyPath1],
                        output[keyPath: keyPath2]
                    ))

                case .pending:
                    self = .pending(base, keyPath0, keyPath1, keyPath2)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
