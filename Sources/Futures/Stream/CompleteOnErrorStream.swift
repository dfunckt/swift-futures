//
//  CompleteOnErrorStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum CompleteOnError<Base: StreamProtocol>: StreamProtocol where Base.Output: _ResultConvertible {
        public typealias Output = Base.Output

        case pending(Base)
        case completed
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    switch output._makeResult() {
                    case .success:
                        self = .pending(base)
                    case .failure:
                        self = .completed
                    }
                    return .ready(output)

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base)
                    return .pending
                }

            case .completed:
                self = .done
                return .ready(nil)

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
