//
//  MergeStream+Arity.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public struct Merge3<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol>: StreamProtocol where A.Output == B.Output, B.Output == C.Output {
        public typealias Output = A.Output

        @usableFromInline var a: A?
        @usableFromInline var b: B?
        @usableFromInline var c: C?
        @usableFromInline var next = 1

        @inlinable
        public init(_ a: A, _ b: B, _ c: C) {
            self.a = a
            self.b = b
            self.c = c
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            var pollCount = 3

            while pollCount > 0 {
                pollCount -= 1

                switch next {
                case 1:
                    next = 2
                    switch a?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        a = nil
                        if a == nil, b == nil, c == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case 2:
                    next = 3
                    switch b?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        b = nil
                        if a == nil, b == nil, c == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case 3:
                    next = 1
                    switch c?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        c = nil
                        if a == nil, b == nil, c == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case .max:
                    fatalError("cannot poll after completion")

                default:
                    fatalError("unreachable")
                }
            }

            return .pending
        }
    }

    public struct Merge4<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol, D: StreamProtocol>: StreamProtocol where A.Output == B.Output, B.Output == C.Output, C.Output == D.Output {
        public typealias Output = A.Output

        @usableFromInline var a: A?
        @usableFromInline var b: B?
        @usableFromInline var c: C?
        @usableFromInline var d: D?
        @usableFromInline var next = 1

        @inlinable
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        }

        @inlinable
        public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
            var pollCount = 4

            while pollCount > 0 {
                pollCount -= 1

                switch next {
                case 1:
                    next = 2
                    switch a?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        a = nil
                        if a == nil, b == nil, c == nil, d == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case 2:
                    next = 3
                    switch b?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        b = nil
                        if a == nil, b == nil, c == nil, d == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case 3:
                    next = 4
                    switch c?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        c = nil
                        if a == nil, b == nil, c == nil, d == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case 4:
                    next = 1
                    switch d?.pollNext(&context) {
                    case .ready(.some(let output)):
                        return .ready(output)
                    case .ready(.none):
                        d = nil
                        if a == nil, b == nil, c == nil, d == nil {
                            next = .max
                            return .ready(nil)
                        }
                        continue
                    case .pending, .none:
                        continue
                    }

                case .max:
                    fatalError("cannot poll after completion")

                default:
                    fatalError("unreachable")
                }
            }

            return .pending
        }
    }
}
