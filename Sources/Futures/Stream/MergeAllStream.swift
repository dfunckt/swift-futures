//
//  MergeAllStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct MergeAll<Base: StreamProtocol> {
        @usableFromInline typealias F = Future<Base>
        @usableFromInline let _futures: LocalScheduler<F.Output, AtomicWaker>

        @inlinable
        public init(_ bases: Base...) {
            self.init(bases)
        }

        @inlinable
        public init<C: Swift.Sequence>(_ bases: C) where C.Element == Base {
            _futures = .init(waker: .init())
            _futures.submit(bases.lazy.map(F.init))
        }
    }
}

extension Stream._Private.MergeAll: StreamProtocol {
    public typealias Output = Base.Output

    @inlinable
    public func pollNext(_ context: inout Context) -> Poll<Output?> {
        _futures.waker.register(context.waker)

        while true {
            switch _futures.pollNext() {
            case .some((.some(let output), let stream)):
                _futures.submit(F(base: stream))
                return .ready(output)
            case .some((.none, _)):
                continue
            case .none where _futures.isEmpty:
                return .ready(nil)
            case .none:
                return .pending
            }
        }
    }
}
