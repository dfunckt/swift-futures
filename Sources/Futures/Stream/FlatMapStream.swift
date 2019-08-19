//
//  FlatMapStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum FlatMap<U: StreamConvertible, Base: StreamProtocol>: StreamProtocol {
        public typealias Output = U.StreamType.Output
        public typealias Transform = (Base.Output) -> U

        case pending(Base, Transform)
        case waiting(Base, Transform, U.StreamType)
        case done

        @inlinable
        public init(base: Base, transform: @escaping Transform) {
            self = .pending(base, transform)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(var base, let transform):
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        let stream = transform(output).makeStream()
                        self = .waiting(base, transform, stream)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(base, transform)
                        return .pending
                    }

                case .waiting(let base, let transform, var stream):
                    switch stream.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .waiting(base, transform, stream)
                        return .ready(output)
                    case .ready(.none):
                        self = .pending(base, transform)
                        continue
                    case .pending:
                        self = .waiting(base, transform, stream)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
