//
//  JoinFuture.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Future._Private {
    public enum Join<A: FutureProtocol, B: FutureProtocol>: FutureProtocol {
        public typealias Output = (A.Output, B.Output)

        case pending(A, B)
        case doneA(A.Output, B)
        case doneB(B.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B) {
            self = .pending(a, b)
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var a, var b):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .doneA(output, b)
                        continue
                    case .pending:
                        switch b.poll(&context) {
                        case .ready(let output):
                            self = .doneB(output, a)
                            continue
                        case .pending:
                            self = .pending(a, b)
                        }
                    }
                case .doneA(let outputA, var b):
                    switch b.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((outputA, output))
                    case .pending:
                        self = .doneA(outputA, b)
                        return .pending
                    }
                case .doneB(let outputB, var a):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((output, outputB))
                    case .pending:
                        self = .doneB(outputB, a)
                        return .pending
                    }
                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}

extension Future._Private {
    public enum Join3<A: FutureProtocol, B: FutureProtocol, C: FutureProtocol>: FutureProtocol {
        public typealias Output = (A.Output, B.Output, C.Output)
        public typealias Rest = Join<B, C>

        case pending(A, Rest)
        case doneA(A.Output, Rest)
        case doneRest(Rest.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C) {
            self = .pending(a, .init(b, c))
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var a, var rest):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .doneA(output, rest)
                        continue
                    case .pending:
                        switch rest.poll(&context) {
                        case .ready(let output):
                            self = .doneRest(output, a)
                            continue
                        case .pending:
                            self = .pending(a, rest)
                            return .pending
                        }
                    }

                case .doneA(let outputA, var rest):
                    switch rest.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((outputA, output.0, output.1))
                    case .pending:
                        self = .doneA(outputA, rest)
                        return .pending
                    }

                case .doneRest(let outputRest, var a):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((output, outputRest.0, outputRest.1))
                    case .pending:
                        self = .doneRest(outputRest, a)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}

extension Future._Private {
    public enum Join4<A: FutureProtocol, B: FutureProtocol, C: FutureProtocol, D: FutureProtocol>: FutureProtocol {
        public typealias Output = (A.Output, B.Output, C.Output, D.Output)
        public typealias Rest = Join3<B, C, D>

        case pending(A, Rest)
        case doneA(A.Output, Rest)
        case doneRest(Rest.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self = .pending(a, .init(b, c, d))
        }

        @inlinable
        public mutating func poll(_ context: inout Context) -> Poll<Output> {
            while true {
                switch self {
                case .pending(var a, var rest):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .doneA(output, rest)
                        continue
                    case .pending:
                        switch rest.poll(&context) {
                        case .ready(let output):
                            self = .doneRest(output, a)
                            continue
                        case .pending:
                            self = .pending(a, rest)
                            return .pending
                        }
                    }

                case .doneA(let outputA, var rest):
                    switch rest.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((outputA, output.0, output.1, output.2))
                    case .pending:
                        self = .doneA(outputA, rest)
                        return .pending
                    }

                case .doneRest(let outputRest, var a):
                    switch a.poll(&context) {
                    case .ready(let output):
                        self = .done
                        return .ready((output, outputRest.0, outputRest.1, outputRest.2))
                    case .pending:
                        self = .doneRest(outputRest, a)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
