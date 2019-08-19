//
//  SequenceStream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    public enum Sequence<C: Swift.Sequence>: StreamProtocol {
        public typealias Output = C.Element

        case pending(C.Iterator)
        case done

        @inlinable
        public init(sequence: C) {
            self = .pending(sequence.makeIterator())
        }

        @inlinable
        public mutating func pollNext(_: inout Context) -> Poll<Output?> {
            switch self {
            case .pending(var iter):
                switch iter.next() {
                case .some(let output):
                    self = .pending(iter)
                    return .ready(output)
                case .none:
                    self = .done
                    return .ready(nil)
                }
            case .done:
                fatalError("cannot poll after completion")
            }
        }
    }
}
