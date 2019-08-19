//
//  SelectAnyFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct SelectAny<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output

        private var _futures: _TaskScheduler<Base>

        public init(_ bases: Base...) {
            self.init(bases)
        }

        public init<C: Sequence>(_ bases: C) where C.Element == Base {
            _futures = .init()
            _futures.schedule(bases)
            precondition(!_futures.isEmpty)
        }

        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            switch _futures.pollNext(&context) {
            case .ready(.some(let output)):
                return .ready(output)
            case .pending:
                return .pending
            case .ready(.none):
                // there's always going to be at least one
                // future in the scheduler until we're done.
                fatalError("unreachable")
            }
        }
    }
}
