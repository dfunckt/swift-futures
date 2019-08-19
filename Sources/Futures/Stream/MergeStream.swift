//
//  MergeStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Merge<A: StreamProtocol, B: StreamProtocol>: StreamProtocol where A.Output == B.Output {
        public typealias Output = A.Output

        case pollA(A, B)
        case pollB(A, B)
        case doneA(B)
        case doneB(A)
        case done

        @inlinable
        public init(_ a: A, _ b: B) {
            self = .pollA(a, b)
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            while true {
                switch self {
                case .pollA(var a, var b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollB(a, b)
                        return .ready(output)
                    case .ready(.none):
                        self = .doneA(b)
                        continue
                    case .pending:
                        switch b.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .pollA(a, b)
                            return .ready(output)
                        case .ready(.none):
                            self = .doneB(a)
                            return .pending
                        case .pending:
                            self = .pollA(a, b)
                            return .pending
                        }
                    }

                case .pollB(var a, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollA(a, b)
                        return .ready(output)
                    case .ready(.none):
                        self = .doneB(a)
                        continue
                    case .pending:
                        switch a.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .pollB(a, b)
                            return .ready(output)
                        case .ready(.none):
                            self = .doneA(b)
                            return .pending
                        case .pending:
                            self = .pollB(a, b)
                            return .pending
                        }
                    }

                case .doneA(var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneA(b)
                        return .ready(output)
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneA(b)
                        return .pending
                    }

                case .doneB(var a):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .doneB(a)
                        return .ready(output)
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .doneB(a)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
