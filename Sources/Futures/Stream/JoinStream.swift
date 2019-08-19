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
