//
//  ZipStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Zip<A: StreamProtocol, B: StreamProtocol> {
        case pending(A, B)
        case pollA(B.Output, A, B)
        case pollB(A.Output, A, B)
        case done

        @inlinable
        public init(_ a: A, _ b: B) {
            self = .pending(a, b)
        }
    }
}

extension Stream._Private.Zip: StreamProtocol {
    public typealias Output = (A.Output, B.Output)

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

// MARK: -

extension Stream._Private {
    public enum Zip3<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol> {
        public typealias Rest = Zip<B, C>

        case pending(A, Rest)
        case pollA(Rest.Output, A, Rest)
        case pollRest(A.Output, A, Rest)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C) {
            self = .pending(a, .init(b, c))
        }
    }
}

extension Stream._Private.Zip3: StreamProtocol {
    public typealias Output = (A.Output, B.Output, C.Output)

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .pending(var a, var rest):
                switch a.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pollRest(output, a, rest)
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    switch rest.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollA(output, a, rest)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(a, rest)
                        return .pending
                    }
                }

            case .pollA(let outputRest, var a, let rest):
                switch a.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(a, rest)
                    return .ready((output, outputRest.0, outputRest.1))
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pollA(outputRest, a, rest)
                    return .pending
                }

            case .pollRest(let outputA, let a, var rest):
                switch rest.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(a, rest)
                    return .ready((outputA, output.0, output.1))
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pollRest(outputA, a, rest)
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
    public enum Zip4<A: StreamProtocol, B: StreamProtocol, C: StreamProtocol, D: StreamProtocol> {
        public typealias Rest = Zip3<B, C, D>

        case pending(A, Rest)
        case pollA(Rest.Output, A, Rest)
        case pollRest(A.Output, A, Rest)
        case done

        @inlinable
        public init(_ a: A, _ b: B, _ c: C, _ d: D) {
            self = .pending(a, .init(b, c, d))
        }
    }
}

extension Stream._Private.Zip4: StreamProtocol {
    public typealias Output = (A.Output, B.Output, C.Output, D.Output)

    @inlinable
    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        while true {
            switch self {
            case .pending(var a, var rest):
                switch a.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pollRest(output, a, rest)
                    continue
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    switch rest.pollNext(&context) {
                    case .ready(.some(let output)):
                        self = .pollA(output, a, rest)
                        continue
                    case .ready(.none):
                        self = .done
                        return .ready(nil)
                    case .pending:
                        self = .pending(a, rest)
                        return .pending
                    }
                }

            case .pollA(let outputRest, var a, let rest):
                switch a.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(a, rest)
                    return .ready((output, outputRest.0, outputRest.1, outputRest.2))
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pollA(outputRest, a, rest)
                    return .pending
                }

            case .pollRest(let outputA, let a, var rest):
                switch rest.pollNext(&context) {
                case .ready(.some(let output)):
                    self = .pending(a, rest)
                    return .ready((outputA, output.0, output.1, output.2))
                case .ready(.none):
                    self = .done
                    return .ready(nil)
                case .pending:
                    self = .pollRest(outputA, a, rest)
                    return .pending
                }

            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
