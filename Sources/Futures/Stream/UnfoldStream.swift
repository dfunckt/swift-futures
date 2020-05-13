//
//  UnfoldStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Unfold<U: FutureConvertible> {
        public typealias Next = (U.FutureType.Output) -> U?

        case initial(Next, U.FutureType.Output)
        case pending(Next, U.FutureType.Output)
        case waiting(Next, U.FutureType)
        case done

        @inlinable
        public init(initial: Output, next: @escaping Next) {
            self = .initial(next, initial)
        }
    }
}

extension Stream._Private.Unfold: StreamProtocol {
    public typealias Output = U.FutureType.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .initial(let next, let initial):
                self = .pending(next, initial)
                return .ready(initial)

            case .pending(let next, let previousOutput):
                if let future = next(previousOutput)?.makeFuture() {
                    self = .waiting(next, future)
                    continue
                }
                self = .done
                return .ready(nil)

            case .waiting(let next, var future):
                switch future.poll(&context) {
                case .ready(let output):
                    self = .pending(next, output)
                    return .ready(output)
                case .pending:
                    self = .waiting(next, future)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
