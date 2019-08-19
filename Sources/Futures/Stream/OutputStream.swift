//
//  OutputStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Output<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base, Int, CountableRange<Int>)
        case done

        @inlinable
        public init(base: Base, range: CountableRange<Int>) {
            self = .pending(base, 0, range)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, var index, let range):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        if range.contains(index) {
                            self = .pending(base, index + 1, range)
                            return .ready(output)
                        }
                        index += 1
                        continue

                    case .ready(.none):
                        self = .done
                        return .ready(nil)

                    case .pending:
                        self = .pending(base, index, range)
                        return .pending
                    }
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
