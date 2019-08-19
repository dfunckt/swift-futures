//
//  ThreadLocal.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)
import Darwin.POSIX.pthread
#else
import Glibc
#endif

@usableFromInline
struct _ThreadLocal<T: AnyObject> {
    @usableFromInline let _key: pthread_key_t

    @inlinable
    init() {
        var key = pthread_key_t()
        let rc = pthread_key_create(&key) { ptr in
            Unmanaged<AnyObject>
                // swiftlint:disable:next force_unwrapping
                .fromOpaque((ptr as UnsafeMutableRawPointer?)!)
                .release()
        }
        precondition(rc == 0, "Could not create TLS key: \(rc)")
        _key = key
    }

    @inlinable
    var value: T? {
        get {
            return pthread_getspecific(_key).map {
                Unmanaged<T>.fromOpaque($0).takeUnretainedValue()
            }
        }
        nonmutating set {
            if let ptr = pthread_getspecific(_key) {
                Unmanaged<T>.fromOpaque(ptr).release()
            }
            let rc = pthread_setspecific(_key, newValue.map {
                Unmanaged.passRetained($0).toOpaque()
            })
            precondition(rc == 0, "Could not create TLS instance: \(rc)")
        }
    }
}
