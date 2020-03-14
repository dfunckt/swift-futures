//
//  BreakpointStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Breakpoint<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        public typealias Ready = (Base.Output) -> Bool
        public typealias Pending = () -> Bool
        public typealias Complete = () -> Bool

        case pending(Base, Ready, Pending, Complete)
        case done

        @inlinable
        public init(base: Base, ready: @escaping Ready, pending: @escaping Pending, complete: @escaping Complete) {
            self = .pending(base, ready, pending, complete)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var base, let ready, let pending, let complete):
                switch base.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(base, ready, pending, complete)
                    if ready(output) {
                        invokeDebugger()
                    }
                    return .ready(output)

                case .ready(.none):
                    self = .done
                    if complete() {
                        invokeDebugger()
                    }
                    return .ready(nil)

                case .pending:
                    self = .pending(base, ready, pending, complete)
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
