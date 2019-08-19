//
//  PollOnStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum PollOn<E: ExecutorProtocol, Base: StreamProtocol>: StreamProtocol {
        public typealias Output = Result<Base.Output, E.Failure>
        public typealias Next = Futures.Future._Private.PollOn<E, Future<Base>>

        case pending(E, Base)
        case waiting(E, Next)
        case done

        @inlinable
        public init(base: Base, executor: E) {
            self = .pending(executor, base)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(let executor, let base):
                    self = .waiting(executor, base.makeFuture().poll(on: executor))
                    continue

                case .waiting(let executor, var future):
                    switch future.poll(&context) {
                    case .ready(.success(let (output, stream))):
                        switch output {
                        case .some(let output):
                            self = .pending(executor, stream)
                            return .ready(.success(output))
                        case .none:
                            self = .done
                            return .ready(nil)
                        }
                    case .ready(.failure(let error)):
                        self = .done
                        return .ready(.failure(error))
                    case .pending:
                        self = .waiting(executor, future)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
