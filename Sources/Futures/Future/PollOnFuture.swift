//
//  PollOnFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum PollOn<E: ExecutorProtocol, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Result<Base.Output, E.Failure>

        case pending(Promise<Base.Output>, E, Base)
        case waiting(Promise<Base.Output>, E)
        case done

        @inlinable
        public init(base: Base, executor: E) {
            self = .pending(.init(), executor, base)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(let promise, let executor, let base):
                    let resolver = promise.resolve(when: base)
                    switch executor.trySubmit(resolver) {
                    case .success:
                        // keep the executor alive while the future is alive
                        self = .waiting(promise, executor)
                        continue
                    case .failure(let error):
                        self = .done
                        return .ready(.failure(error))
                    }

                case .waiting(let promise, _):
                    switch promise.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready(.success(output))
                    case .pending:
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
