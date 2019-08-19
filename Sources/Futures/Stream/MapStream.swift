//
//  MapStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Map<Output, Base: StreamProtocol>: StreamProtocol {
        public typealias Transform = (Base.Output) -> Output

        case pending(Base, Transform)
        case done

        @inlinable
        public init(base: Base, transform: @escaping Transform) {
            self = .pending(base, transform)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let transform):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, transform)
                    return .ready(transform(output))

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

extension Stream._Private.Map where Base.Output == Output? {
    @inlinable
    public init(replacingNilFrom base: Base, with output: Output) {
        self = .pending(base) { $0 ?? output }
    }
}
