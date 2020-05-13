//
//  PrefixUntilOutputStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum PrefixUntilOutput<Other: FutureProtocol, Base: StreamProtocol> {
        case pending(Base, Other)
        case done

        @inlinable
        public init(base: Base, future: Other) {
            self = .pending(base, future)
        }
    }
}

extension Stream._Private.PrefixUntilOutput: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        switch self {
        case .pending(var base, var future):
            switch future.poll(&context) {
            case .ready:
                self = .done
                return .ready(nil)
            case .pending:
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, future)
                    return .ready(output)

                case .ready(.none):
                    self = .done
                    return .ready(nil)

                case .pending:
                    self = .pending(base, future)
                    return .pending
                }
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
