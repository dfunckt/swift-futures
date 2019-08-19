//
//  Stream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

public struct TestStream<S: Sequence>: StreamProtocol {
    public typealias Output = S.Element

    private var _iter: EnumeratedSequence<S>.Iterator
    private let _yieldOnIndex: Int
    private var _lastElement: Output?

    public init(elements: S, yieldOnIndex: Int?) {
        _yieldOnIndex = yieldOnIndex ?? Int.random(in: 0..<elements.underestimatedCount)
        _iter = elements.enumerated().makeIterator()
    }

    public mutating func pollNext(_ context: inout Context) -> Poll<Output?> {
        if let output = _lastElement {
            _lastElement = nil
            return .ready(output)
        }
        if let (index, output) = _iter.next() {
            if index == _yieldOnIndex {
                _lastElement = output
                return context.yield()
            }
            return .ready(output)
        }
        return .ready(nil)
    }
}

public func makeStream<S: Sequence>(_ elements: S, yieldOnIndex: Int? = nil) -> TestStream<S> {
    return .init(elements: elements, yieldOnIndex: yieldOnIndex)
}
