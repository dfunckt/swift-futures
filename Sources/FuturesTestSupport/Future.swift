//
//  Future.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Dispatch
import Foundation
import Futures
import FuturesSync

public func pending() -> AnyFuture<Void> {
    return .init { _ in
        .pending
    }
}

public func `lazy`<T>(_ fn: @escaping () -> T) -> AnyFuture<T> {
    return .init { _ in
        .ready(fn())
    }
}

public func delayed<T>(by: TimeInterval, _ fn: @escaping () -> T) -> AnyFuture<T> {
    let flag = AtomicBool(false)
    return .init { context in
        if !flag.load(order: .acquire) {
            let waker = context.waker
            DispatchQueue.global().asyncAfter(deadline: .now() + by) {
                flag.store(true, order: .release)
                waker.signal()
            }
            if !flag.load(order: .acquire) {
                return .pending
            }
        }
        return .ready(fn())
    }
}

public struct TestFuture<Output>: FutureProtocol {
    private var _output: Output?

    public init(output: Output) {
        _output = output
    }

    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        if let output = _output {
            _output = nil
            return .ready(output)
        }
        return context.yield()
    }
}

public func makeFuture<T>(_ output: T) -> TestFuture<T> {
    return .init(output: output)
}
