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
