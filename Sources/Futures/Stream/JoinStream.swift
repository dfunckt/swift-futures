//
//  JoinStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Join<A: StreamProtocol, B: StreamProtocol>: StreamProtocol {
        public typealias Output = (A.Output, B.Output)

        case pending(A, B)
        case waitingA(B.Output, A, B)
        case waitingB(A.Output, A, B)
        case polling(A.Output, B.Output, A, B)
        case doneA(A.Output, B)
        case doneB(B.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B) {
            self = .pending(a, b)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(var a, var b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .waitingB(output, a, b)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        switch b.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .waitingA(output, a, b)
                            continue
                        case .ready(.none):
                            self = .done
                            return .ready(nil)
                        case .pending:
                            self = .pending(a, b)
                            return .pending
                        }
                    }

                case .waitingA(let outputB, var a, let b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingA(outputB, a, b)
                        return .pending
                    }

                case .waitingB(let outputA, let a, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingB(outputA, a, b)
                        return .pending
                    }

                case .polling(let outputA, let outputB, var a, var b):
                    switch (a.pollNext(&context), b.pollNext(&context)) {
                    case (.ready(.some(let eA)), .ready(.some(let eB))):
                        self = .polling(eA, eB, a, b)
                        return .ready((eA, eB))
                    case (.ready(.some(let output)), .ready(.none)):
                        self = .doneB(outputB, a)
                        return .ready((output, outputB))
                    case (.ready(.some(let output)), .pending):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB))
                    case (.ready(.none), .ready(.some(let output))):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output))
                    case (.ready(.none), .ready(.none)):
                        self = .done
                        return .ready(nil)
                    case (.ready(.none), .pending):
                        self = .doneA(outputA, b)
                        return .pending
                    case (.pending, .ready(.some(let output))):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output))
                    case (.pending, .ready(.none)):
                        self = .doneB(outputB, a)
                        return .pending
                    case (.pending, .pending):
                        self = .polling(outputA, outputB, a, b)
                        return .pending
                    }

                case .doneA(let outputA, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneA(outputA, b)
                        return .pending
                    }

                case .doneB(let outputB, var a):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneB(outputB, a)
                        return .ready((output, outputB))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
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

extension Stream._Private {
    public enum Join3<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol>: StreamProtocol {
        public typealias Output = (A.Output, B.Output, C.Output)
        public typealias Rest = Join<B, C>

        case pending(A, Rest)
        case waitingA(Rest.Output, A, Rest)
        case waitingRest(A.Output, A, Rest)
        case polling(A.Output, Rest.Output, A, Rest)
        case doneA(A.Output, Rest)
        case doneRest(Rest.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C) {
            self = .pending(a, .init(b, c))
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(var a, var b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .waitingRest(output, a, b)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        switch b.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .waitingA(output, a, b)
                            continue
                        case .ready(.none):
                            self = .done
                            return .ready(nil)
                        case .pending:
                            self = .pending(a, b)
                            return .pending
                        }
                    }

                case .waitingA(let outputB, var a, let b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB.0, outputB.1))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingA(outputB, a, b)
                        return .pending
                    }

                case .waitingRest(let outputA, let a, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output.0, output.1))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingRest(outputA, a, b)
                        return .pending
                    }

                case .polling(let outputA, let outputB, var a, var b):
                    switch (a.pollNext(&context), b.pollNext(&context)) {
                    case (.ready(.some(let eA)), .ready(.some(let eB))):
                        self = .polling(eA, eB, a, b)
                        return .ready((eA, eB.0, eB.1))
                    case (.ready(.some(let output)), .ready(.none)):
                        self = .doneRest(outputB, a)
                        return .ready((output, outputB.0, outputB.1))
                    case (.ready(.some(let output)), .pending):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB.0, outputB.1))
                    case (.ready(.none), .ready(.some(let output))):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output.0, output.1))
                    case (.ready(.none), .ready(.none)):
                        self = .done
                        return .ready(nil)
                    case (.ready(.none), .pending):
                        self = .doneA(outputA, b)
                        return .pending
                    case (.pending, .ready(.some(let output))):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output.0, output.1))
                    case (.pending, .ready(.none)):
                        self = .doneRest(outputB, a)
                        return .pending
                    case (.pending, .pending):
                        self = .polling(outputA, outputB, a, b)
                        return .pending
                    }

                case .doneA(let outputA, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output.0, output.1))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneA(outputA, b)
                        return .pending
                    }

                case .doneRest(let outputB, var a):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneRest(outputB, a)
                        return .ready((output, outputB.0, outputB.1))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneRest(outputB, a)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}

extension Stream._Private {
    public enum Join4<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol, D: StreamProtocol>: StreamProtocol {
        public typealias Output = (A.Output, B.Output, C.Output, D.Output)
        public typealias Rest = Join3<B, C, D>

        case pending(A, Rest)
        case waitingA(Rest.Output, A, Rest)
        case waitingRest(A.Output, A, Rest)
        case polling(A.Output, Rest.Output, A, Rest)
        case doneA(A.Output, Rest)
        case doneRest(Rest.Output, A)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self = .pending(a, .init(b, c, d))
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pending(var a, var b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .waitingRest(output, a, b)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        switch b.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .waitingA(output, a, b)
                            continue
                        case .ready(.none):
                            self = .done
                            return .ready(nil)
                        case .pending:
                            self = .pending(a, b)
                            return .pending
                        }
                    }

                case .waitingA(let outputB, var a, let b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB.0, outputB.1, outputB.2))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingA(outputB, a, b)
                        return .pending
                    }

                case .waitingRest(let outputA, let a, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output.0, output.1, output.2))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .waitingRest(outputA, a, b)
                        return .pending
                    }

                case .polling(let outputA, let outputB, var a, var b):
                    switch (a.pollNext(&context), b.pollNext(&context)) {
                    case (.ready(.some(let eA)), .ready(.some(let eB))):
                        self = .polling(eA, eB, a, b)
                        return .ready((eA, eB.0, eB.1, eB.2))
                    case (.ready(.some(let output)), .ready(.none)):
                        self = .doneRest(outputB, a)
                        return .ready((output, outputB.0, outputB.1, outputB.2))
                    case (.ready(.some(let output)), .pending):
                        self = .polling(output, outputB, a, b)
                        return .ready((output, outputB.0, outputB.1, outputB.2))
                    case (.ready(.none), .ready(.some(let output))):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output.0, output.1, output.2))
                    case (.ready(.none), .ready(.none)):
                        self = .done
                        return .ready(nil)
                    case (.ready(.none), .pending):
                        self = .doneA(outputA, b)
                        return .pending
                    case (.pending, .ready(.some(let output))):
                        self = .polling(outputA, output, a, b)
                        return .ready((outputA, output.0, output.1, output.2))
                    case (.pending, .ready(.none)):
                        self = .doneRest(outputB, a)
                        return .pending
                    case (.pending, .pending):
                        self = .polling(outputA, outputB, a, b)
                        return .pending
                    }

                case .doneA(let outputA, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneA(outputA, b)
                        return .ready((outputA, output.0, output.1, output.2))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneA(outputA, b)
                        return .pending
                    }

                case .doneRest(let outputB, var a):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneRest(outputB, a)
                        return .ready((output, outputB.0, outputB.1, outputB.2))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneRest(outputB, a)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
