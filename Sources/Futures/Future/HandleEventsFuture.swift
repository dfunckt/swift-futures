//
//  HandleEventsFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum HandleEvents<Base: FutureProtocol> {
        public typealias Ready = (Base.Output) -> Void
        public typealias Pending = () -> Void

        case pending(Base, Ready, Pending)
        case done

        @inlinable
        public init(base: Base, ready: @escaping Ready, pending: @escaping Pending) {
            self = .pending(base, ready, pending)
        }
    }
}

extension Future._Private.HandleEvents: FutureProtocol {
    public typealias Output = Base.Output

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .pending(var base, let ready, let pending):
            switch base.poll(&context) {
            case .ready(let output):
                self = .done
                ready(output)
                return .ready(output)

            case .pending:
                self = .pending(base, ready, pending)
                pending()
                return .pending
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}
