//
//  Synchronized.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesSync

@usableFromInline
internal final class Synchronized<T> {
    @usableFromInline var _locked: AtomicBool.RawValue = false
    @usableFromInline var _base: T

    @inlinable
    internal init(base: T) {
        _base = base
        AtomicBool.initialize(&_locked, to: false)
    }

    @inlinable
    @inline(__always)
    internal func barrier<R>(
        _ context: inout Context,
        _ block: (inout T, inout Context) -> Poll<R>
    ) -> Poll<R> {
        if !AtomicBool.exchange(&_locked, true, order: .acquire) {
            let result = block(&_base, &context)
            AtomicBool.store(&_locked, false, order: .release)
            return result
        } else {
            return context.yield()
        }
    }
}
