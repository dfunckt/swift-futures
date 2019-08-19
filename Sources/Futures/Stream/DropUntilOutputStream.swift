//
//  DropUntilOutputStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum DropUntilOutput<Other: FutureProtocol, Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        case pending(Base, Other)
        case flushing(Base)
        case done

        @inlinable
        public init(base: Base, future: Other) {
            self = .pending(base, future)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, var future):
                while true {
                    switch base.pollNext(&context) {
                    case .ready(.some(let output)):
                        switch future.poll(&context) {
                        case .ready:
                            self = .flushing(base)
                            return .ready(output)
                        case .pending:
                            continue
                        }
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(base, future)
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
}
