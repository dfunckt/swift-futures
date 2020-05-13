//
//  SwitchToLatestStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum SwitchToLatest<Base: StreamProtocol> where Base.Output: StreamConvertible {
        case pending(Base)
        case following(Base, Base.Output.StreamType)
        case flushing(Base.Output.StreamType)
        case done

        @inlinable
        public init(base: Base) {
            self = .pending(base)
        }
    }
}

extension Stream._Private.SwitchToLatest: StreamProtocol {
    public typealias Output = Base.Output.StreamType.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .pending(var base):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    let stream = output.makeStream()
                    self = .following(base, stream)
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pending(base)
                    return .pending
                }

            case .following(var base, var stream):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    let stream = output.makeStream()
                    self = .following(base, stream)
                    continue
                case .ready(.none):
                    self = .flushing(stream)
                    continue
                case .pending:
                    switch stream.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .following(base, stream)
                        return .ready(output)
                    case .ready(.none):
                        self = .pending(base)
                        continue
                    case .pending:
                        self = .following(base, stream)
                        return .pending
                    }
                }

            case .flushing(var stream):
                switch stream.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .flushing(stream)
                    return .ready(output)
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .flushing(stream)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
