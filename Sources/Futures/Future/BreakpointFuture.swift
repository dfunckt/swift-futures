//
//  BreakpointFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Breakpoint<Base: FutureProtocol> {
        public typealias Ready = (Base.Output) -> Bool
        public typealias Pending = () -> Bool

        case pending(Base, Ready, Pending)
        case done

        @inlinable
        public init(base: Base, ready: @escaping Ready, pending: @escaping Pending) {
            self = .pending(base, ready, pending)
        }
    }
}

extension Future._Private.Breakpoint {
    @inlinable
    public init<Success, Failure>(base: Base) where Base.Output == Result<Success, Failure> {
        self.init(base: base, ready: { $0._isFailure }, pending: { false })
    }
}

extension Future._Private.Breakpoint: FutureProtocol {
    public typealias Output = Base.Output

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
