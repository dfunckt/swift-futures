//
//  MergeStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Merge<A: StreamProtocol, B: StreamProtocol> where A.Output == B.Output {
        case pollA(A, B)
        case pollB(A, B)
        case doneA(B)
        case doneB(A)
        case done

        @inlinable
        public init(_ a: A, _ b: B) {
            self = .pollA(a, b)
        }
    }
}

extension Stream._Private.Merge: StreamProtocol {
    public typealias Output = A.Output

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

// MARK: -

extension Stream._Private {
    public struct Merge3<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol> where A.Output == B.Output, B.Output == C.Output {
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
    }
}

extension Stream._Private.Merge3: StreamProtocol {
    public typealias Output = A.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        var pollCount = 3

        while pollCount > 0 {
            pollCount -= 1

            switch next {
            case 1:
                next = 2
                switch a?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    a = nil
                    if a == nil, b == nil, c == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
                    continue
                }

            case 2:
                next = 3
                switch b?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    b = nil
                    if a == nil, b == nil, c == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
                    continue
                }

            case 3:
                next = 1
                switch c?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    c = nil
                    if a == nil, b == nil, c == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
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

// MARK: -

extension Stream._Private {
    public struct Merge4<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol, D: StreamProtocol> where A.Output == B.Output, B.Output == C.Output, C.Output == D.Output {
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
    }
}

extension Stream._Private.Merge4: StreamProtocol {
    public typealias Output = A.Output

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        var pollCount = 4

        while pollCount > 0 {
            pollCount -= 1

            switch next {
            case 1:
                next = 2
                switch a?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    a = nil
                    if a == nil, b == nil, c == nil, d == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
                    continue
                }

            case 2:
                next = 3
                switch b?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    b = nil
                    if a == nil, b == nil, c == nil, d == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
                    continue
                }

            case 3:
                next = 4
                switch c?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    c = nil
                    if a == nil, b == nil, c == nil, d == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
                    continue
                }

            case 4:
                next = 1
                switch d?.pollNext(&context) {
                case .some(.ready(.some(let output))):
                    return .ready(output)
                case .some(.ready(.none)):
                    d = nil
                    if a == nil, b == nil, c == nil, d == nil {
                        next = .max
                        return .ready(nil)
                    }
                    continue
                case .some(.pending), .none:
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
