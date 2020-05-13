//
//  DropWhileStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum DropWhile<Base: StreamProtocol> {
        public typealias Predicate = (Base.Output) -> Bool

        case dropping(Base, Predicate)
        case flushing(Base)
        case done

        @inlinable
        public init(base: Base, predicate: @escaping Predicate) {
            self = .dropping(base, predicate)
        }
    }
}

extension Stream._Private.DropWhile: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .dropping(var base, let predicate):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    if predicate(output) {
                        continue
                    }
                    self = .flushing(base)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .dropping(base, predicate)
                    return .pending
                }
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
