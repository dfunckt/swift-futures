//
//  PrintFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Print<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output

        case pending(Base, String, TextOutputStream)
        case done

        @inlinable
        public init(base: Base, prefix: String, to stream: TextOutputStream?) {
            self = .pending(base, prefix, stream ?? _StandardOutputStream())
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let prefix, var stream):
                let result = base.poll(&context)
                if result.isReady {
                    self = .done
                } else {
                    self = .pending(base, prefix, stream)
                }
                let message = _makeMessage(prefix: prefix, result: result)
                stream.write(message)
                return result

            case .done:
                fatalError("cannot poll after completion")
            }
        }

        @inlinable
        func _makeMessage(prefix: String, result: Poll<Output>) -> String {
            var parts = [String]()
            if !prefix.isEmpty {
                parts.append(prefix)
            }
            switch result {
            case .ready(let output):
                parts.append(".ready(\(output))")
            case .pending:
                parts.append(".pending")
            }
            return parts.joined(separator: " ") + "\n"
        }
    }
}
