//
//  StreamReplayBuffer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

extension Stream._Private {
    @usableFromInline
    enum _ReplayBuffer<Output> {
        case none
        case just(Output?)
        case some(CircularBuffer<Output>)
        case all([Output])
    }
}

extension Stream._Private._ReplayBuffer {
    @inlinable
    init(strategy: Stream.ReplayStrategy) {
        switch strategy {
        case .none:
            self = .none
        case .latest:
            self = .just(nil)
        case .last(let count):
            self = .some(.init(capacity: count))
        case .all:
            self = .all(.init())
        }
    }

    @inlinable
    mutating func push(_ element: Output) {
        switch self {
        case .none:
            break
        case .just:
            self = .just(element)
        case .some(var buf):
            buf.push(element, expand: false)
            self = .some(buf)
        case .all(var elements):
            elements.append(element)
            self = .all(elements)
        }
    }

    @inlinable
    func copyElements() -> [Output] {
        switch self {
        case .none:
            return []
        case .just(.none):
            return []
        case .just(.some(let element)):
            return [element]
        case .some(let buf):
            return buf.copyElements()
        case .all(let elements):
            return elements
        }
    }
}
