//
//  MergeAllStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct MergeAll<Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Base.Output

        private typealias F = Future<Base>
        private let _futures = _TaskScheduler<F>()

        public init(_ bases: Base...) {
            _futures.schedule(bases.lazy.map(F.init))
        }

        public init<C: Swift.Sequence>(_ bases: C) where C.Element == Base {
            _futures.schedule(bases.lazy.map(F.init))
        }

        public func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch _futures.pollNext(&context) {
                case .ready(.some((.some(let output), let stream))):
                    _futures.schedule(.init(base: stream))
                    return .ready(output)
                case .ready(.some((.none, _))):
                    continue
                case .ready(.none):
                    return .ready(nil)
                case .pending:
                    return .pending
                }
            }
        }
    }
}
