//
//  TryMapFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum TryMap<T, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Result<T, Error>
        public typealias Transform = (Base.Output) throws -> T

        case pending(Base, Transform)
        case done

        @inlinable
        public init(base: Base, catching: @escaping Transform) {
            self = .pending(base, catching)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let transform):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    do {
                        return try .ready(.success(transform(output)))
                    } catch {
                        return .ready(.failure(error))
                    }

                case .pending:
                    self = .pending(base, transform)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
