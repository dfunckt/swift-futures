//
//  SelectAnyFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct SelectAny<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Base.Output

        @usableFromInline var _futures: LocalScheduler<Output, AtomicWaker>

        @inlinable
        public init(_ bases: Base...) {
            self.init(bases)
        }

        @inlinable
        public init<C: Sequence>(_ bases: C) where C.Element == Base {
            _futures = .init(waker: .init())
            let count = _futures.submit(bases)
            precondition(count > 0)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            _futures.waker.register(context.waker)

            if let output = _futures.pollNext() {
                return .ready(output)
            }

            return .pending
        }
    }
}
