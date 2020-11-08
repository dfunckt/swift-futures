//
//  PrintStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Print<Base: StreamProtocol> {
        case pending(Base, String, TextOutputStream)
        case done

        @inlinable
        public init(base: Base, prefix: String, to stream: TextOutputStream?) {
            self = .pending(base, prefix, stream ?? StandardOutputStream())
        }
    }
}

extension Stream._Private.Print: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(var base, let prefix, var stream):
            let result = base.pollNext(&context)
            switch result {
            case .ready(.none):
                self = .done
            default:
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
    func _makeMessage(prefix: String, result: Poll<Output?>) -> String {
        var parts = [String]()
        if !prefix.isEmpty {
            parts.append(prefix)
        }
        switch result {
        case .ready(.some(let output)):
            parts.append(".ready(\(output))")
        case .ready(.none):
            parts.append(".ready(nil)")
        case .pending:
            parts.append(".pending")
        }
        return parts.joined(separator: " ") + "\n"
    }
}
