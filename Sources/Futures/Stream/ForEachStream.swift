//
//  ForEachStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum ForEach<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output
        public typealias Inspect = (Base.Output) -> Void

        case pending(Base, Inspect)
        case done

        @inlinable
        public init(base: Base, inspect: @escaping Inspect) {
            self = .pending(base, inspect)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let inspect):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, inspect)
                    inspect(output)
                    return .ready(output)

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, inspect)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
