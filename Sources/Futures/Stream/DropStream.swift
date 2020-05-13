//
//  DropStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Drop<Base: StreamProtocol> {
        case dropping(Base, Int)
        case flushing(Base)
        case done

        @inlinable
        public init(base: Base, count: Int) {
            self = .dropping(base, count)
        }
    }
}

extension Stream._Private.Drop: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .dropping(let base, 0):
                self = .flushing(base)
                continue

            case .dropping(var base, let count):
                switch base.pollNext(&context) {
                case .ready(.some):
                    self = .dropping(base, count - 1)
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .dropping(base, count)
                    return .pending
                }

            case .flushing(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .flushing(base)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .flushing(base)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
