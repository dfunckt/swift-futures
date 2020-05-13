//
//  CompactMapStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum CompactMap<Output, Base: StreamProtocol> {
        public typealias Transform = (Base.Output) -> Output?

        case pending(Base, Transform)
        case done

        @inlinable
        public init(base: Base, transform: @escaping Transform) {
            self = .pending(base, transform)
        }
    }
}

extension Stream._Private.CompactMap: StreamProtocol {
    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(var base, let transform):
            while true {
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    if let output = transform(output) {
                        self = .pending(base, transform)
                        return .ready(output)
                    }
                    continue

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, transform)
                    return .pending
                }
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
