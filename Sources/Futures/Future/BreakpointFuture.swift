//
//  BreakpointFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Breakpoint<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output

        public typealias Ready = (Base.Output) -> Bool
        public typealias Pending = () -> Bool

        case pending(Base, Ready, Pending)
        case done

        @inlinable
        public init(base: Base, ready: @escaping Ready, pending: @escaping Pending) {
            self = .pending(base, ready, pending)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch self {
            case .pending(var base, let ready, let pending):
                switch base.poll(&context) {
                case .ready(let output):
                    self = .done
                    if ready(output) {
                        invokeDebugger()
                    }
                    return .ready(output)

                case .pending:
                    self = .pending(base, ready, pending)
                    if pending() {
                        invokeDebugger()
                    }
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
