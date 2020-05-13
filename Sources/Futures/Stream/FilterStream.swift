//
//  FilterStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Filter<Base: StreamProtocol> {
        public typealias Predicate = (Base.Output) -> Bool

        case pending(Base, Predicate)
        case done

        @inlinable
        public init(base: Base, isIncluded: @escaping Predicate) {
            self = .pending(base, isIncluded)
        }
    }
}

extension Stream._Private.Filter: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(var base, let isIncluded):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    if isIncluded(output) {
                        self = .pending(base, isIncluded)
                        return .ready(output)
                    }
                    continue

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, isIncluded)
                    return .pending
                }
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
