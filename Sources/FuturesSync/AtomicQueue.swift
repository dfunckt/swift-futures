//
//  AtomicQueue.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

public protocol AtomicQueueProtocol {
    associatedtype Element
    func tryPush(_ element: Element) -> Bool
    func pop() -> Element?
}

public protocol AtomicUnboundedQueueProtocol: AtomicQueueProtocol {
    associatedtype Element
    func push(_ element: Element)
}

extension AtomicUnboundedQueueProtocol {
    @inlinable
    public func tryPush(_ element: Element) -> Bool {
        push(element)
        return true
    }
}
