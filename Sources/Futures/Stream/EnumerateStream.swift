//
//  EnumerateStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Enumerate<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = (offset: Int, output: Base.Output)

        case pending(Base, Int)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base, 0)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let offset):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, offset + 1)
                    return .ready((offset, output))

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, offset)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
