//
//  YieldStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Yield<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base, Int, Int)
        case done

        @inlinable
        public init(base: Base, maxElements: Int) {
            precondition(maxElements > 0)
            self = .pending(base, 0, maxElements)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let count, let maxElements):
                if count == maxElements {
                    self = .pending(base, 0, maxElements)
                    return context.yield()
                }
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, count + 1, maxElements)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pending(base, 0, maxElements)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
