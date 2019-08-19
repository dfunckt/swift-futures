//
//  ThenFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Then<E: ExecutorProtocol, U: FutureConvertible, Base: FutureProtocol>: FutureProtocol {
        public typealias Output = Result<U.FutureType.Output, E.Failure>
        public typealias Continuation = (Base.Output) -> U

        @usableFromInline
        enum _Remote: FutureProtocol {
            @usableFromInline typealias Output = U.FutureType.Output

            case pending(Base.Output, Continuation)
            case waiting(U.FutureType)
            case done

            @inlinable
            init(output: Base.Output, continuation: @escaping Continuation) {
                self = .pending(output, continuation)
            }

            @inlinable
            mutating func poll(_ context: inout Context) -> Poll<Output> {
                while true {
                    switch self {
                    case .pending(let output, let transform):
                        let future = transform(output).makeFuture()
                        self = .waiting(future)
                        continue

                    case .waiting(var future):
                        switch future.poll(&context) {
                        case .ready(let output):
                            self = .done
                            return .ready(output)
                        case .pending:
                            self = .waiting(future)
                            return .pending
                        }

                    case .done:
                        fatalError("cannot poll after completion")
                    }
                }
            }
        }

        case pending(Base, E, Continuation)
        case waiting(Task<U.FutureType.Output>)
        case done

        @inlinable
        public init(base: Base, executor: E, continuation: @escaping Continuation) {
            self = .pending(base, executor, continuation)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var base, let executor, let continuation):
                    switch base.poll(&context) {
                    case .ready(let output):
                        let future = _Remote(
                            output: output,
                            continuation: continuation
                        )

                        // FIXME: runtime allocation
                        switch executor.trySpawn(future) {
                        case .success(let task):
                            self = .waiting(task)
                            continue
                        case .failure(let error):
                            self = .done
                            return .ready(.failure(error))
                        }

                    case .pending:
                        self = .pending(base, executor, continuation)
                        return .pending
                    }

                case .waiting(let task):
                    switch task.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready(.success(output))
                    case .pending:
                        self = .waiting(task)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
