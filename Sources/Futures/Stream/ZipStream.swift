//
//  ZipStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Zip<A: StreamProtocol, B: StreamProtocol>: StreamProtocol {
        public typealias Output = (A.Output, B.Output)

        case pending(A, B)
        case pollA(B.Output, A, B)
        case pollB(A.Output, A, B)
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
                        self = .pollB(output, a, b)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        switch b.pollNext(&context) {
                        case .ready(.some(let output)):
                            self = .pollA(output, a, b)
                            continue
                        case .ready(.none):
                            self = .done
                            return .ready(nil)
                        case .pending:
                            self = .pending(a, b)
                            return .pending
                        }
                    }

                case .pollA(let outputB, var a, let b):
                    switch a.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pending(a, b)
                        return .ready((output, outputB))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pollA(outputB, a, b)
                        return .pending
                    }

                case .pollB(let outputA, let a, var b):
                    switch b.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pending(a, b)
                        return .ready((outputA, output))
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pollB(outputA, a, b)
                        return .pending
                    }

                case .done:
                    fatalError("cannot poll after completion")
                }
            }
        }
    }
}
