//
//  TryMapStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum TryMap<T, Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Result<T, Error>
        public typealias Transform = (Base.Output) throws -> T

        case pending(Base, Transform)
        case done

        @inlinable
        public init(base: Base, catching: @escaping Transform) {
            self = .pending(base, catching)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let transform):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, transform)
                    do {
                        return try .ready(.success(transform(output)))
                    } catch {
                        return .ready(.failure(error))
                    }

                case .ready(.none):
                    self = .done
                    return .ready(nil)

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
