//
//  FlattenStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Flatten<Base: StreamProtocol>: StreamProtocol where Base.Output: StreamConvertible {
        public typealias Output = Base.Output.StreamType.Output

        case pending(Base)
        case flushing(Base, Base.Output.StreamType)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(var base):
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        let stream = output.makeStream()
                        self = .flushing(base, stream)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(base)
                        return .pending
                    }

                case .flushing(let base, var stream):
                    switch stream.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .flushing(base, stream)
                        return .ready(output)
                    case .ready(.none):
                        self = .pending(base)
                        continue
                    case .pending:
                        self = .flushing(base, stream)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
