//
//  ConcatenateStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Concatenate<Prefix: StreamProtocol, Suffix: StreamProtocol>: StreamProtocol where Suffix.Output == Prefix.Output {
        public typealias Output = Suffix.Output

        case pollPrefix(Prefix, Suffix)
        case pollSuffix(Suffix)
        case done

        @inlinable
        public init(prefix: Prefix, suffix: Suffix) {
            self = .pollPrefix(prefix, suffix)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pollPrefix(var prefix, let suffix):
                    switch prefix.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollPrefix(prefix, suffix)
                        return .ready(output)
                    case .ready(.none):
                        self = .pollSuffix(suffix)
                        continue
                    case .pending:
                        self = .pollPrefix(prefix, suffix)
                        return .pending
                    }

                case .pollSuffix(var suffix):
                    switch suffix.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollSuffix(suffix)
                        return .ready(output)
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pollSuffix(suffix)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
