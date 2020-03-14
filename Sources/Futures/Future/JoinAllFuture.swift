//
//  JoinAllFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct JoinAll<Base: FutureProtocol> {
        @usableFromInline
        enum Inner {
            case pending(Int, Base)
            case done

            @inlinable
            init(index: Int, base: Base) {
                self = .pending(index, base)
            }
        }

        @usableFromInline let _futures: LocalScheduler<Inner.Output, AtomicWaker>
        @usableFromInline var _results: [Base.Output?]

        @inlinable
        public init(_ bases: Base...) {
            self.init(bases)
        }

        @inlinable
        public init<C: Sequence>(_ bases: C) where C.Element == Base {
            _futures = .init(waker: .init())
            let count = _futures.submit(bases.lazy.enumerated().map(Inner.init))
            _results = .init(repeating: nil, count: count)
        }
    }
}

extension Future._Private.JoinAll.Inner: FutureProtocol {
    @usableFromInline typealias Output = (Int, Base.Output)

    @inlinable
    mutating func poll(_ context: inout Context) -> Poll<Output> {
        switch self {
        case .pending(let index, var base):
            switch base.poll(&context) {
            case .ready(let output):
                self = .done
                return .ready((index, output))
            case .pending:
                self = .pending(index, base)
                return .pending
            }

        case .done:
            fatalError("cannot poll after completion")
        }
    }
}

extension Future._Private.JoinAll: FutureProtocol {
    public typealias Output = [Base.Output]

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        _futures.waker.register(context.waker)

        while let (index, output) = _futures.pollNext() {
            _results[index] = output
        }

        if _futures.isEmpty {
            var results = [Base.Output]()
            results.reserveCapacity(_results.count)
            results.append(contentsOf: _results.lazy.compactMap { $0 })
            _results = []
            _futures.destroy()
            return .ready(results)
        }

        return .pending
    }
}
