//
//  FutureStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Stream<Base: FutureProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base)
        case complete
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base):
                switch base.poll(&context) {
                case .ready(let result):
                    self = .complete
                    return .ready(result)
                case .pending:
                    self = .pending(base)
                    return .pending
                }

            case .complete:
                self = .done
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
