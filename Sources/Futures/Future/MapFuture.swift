//
//  MapFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Map<Output, Base: FutureProtocol> {
        public typealias Transform = (Base.Output) -> Output

        case pending(Base, Transform)
        case done

        @inlinable
        public init(base: Base, transform: @escaping Transform) {
            self = .pending(base, transform)
        }
    }
}

extension Future._Private.Map: FutureProtocol {
    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .pending(var base, let transform):
            switch base.poll(&context) {
            case .ready(let output):
                self = .done
                return .ready(transform(output))

            case .pending:
                self = .pending(base, transform)
                return .pending
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
