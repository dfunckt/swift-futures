//
//  JoinAllFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public struct JoinAll<Base: FutureProtocol>: FutureProtocol {
        public typealias Output = [Base.Output]

        private enum _Inner: FutureProtocol {
            typealias Output = (Int, Base.Output)

            case pending(Int, Base)
            case done

            init(index: Int, base: Base) {
                self = .pending(index, base)
            }

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

        private var _futures = _TaskScheduler<_Inner>()
        private var _results: [Base.Output?]

        public init(_ bases: Base...) {
            self.init(bases)
        }

        public init<C: Sequence>(_ bases: C) where C.Element == Base {
            _futures.schedule(bases.lazy.enumerated().map(_Inner.init))
            _results = .init(repeating: nil, count: _futures.count)
        }

        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch _futures.pollNext(&context) {
                case .ready(.some(let (index, result))):
                    _results[index] = result
                    continue

                case .ready(.none):
                    var results = [Base.Output]()
                    results.reserveCapacity(_results.count)
                    results.append(contentsOf: _results.lazy.compactMap { $0 })
                    _results = []
                    return .ready(results)

                case .pending:
                    return .pending
                }
            }
        }
    }
}
