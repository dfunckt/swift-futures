//
//  LazyStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Lazy<U: StreamConvertible> {
        public typealias Constructor = () -> U

        case pending(Constructor)
        case waiting(U.StreamType)
        case done

        @inlinable
        public init(_ body: @escaping Constructor) {
            self = .pending(body)
        }
    }
}

extension Stream._Private.Lazy: StreamProtocol {
    public typealias Output = U.StreamType.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .pending(let constructor):
                let s = constructor()
                self = .waiting(s.makeStream())
                continue

            case .waiting(var stream):
                switch stream.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .waiting(stream)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .waiting(stream)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
