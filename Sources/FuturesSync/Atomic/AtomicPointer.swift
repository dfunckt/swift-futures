//
//  AtomicPointer.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPrivate

// MARK: - Bool -

extension AtomicBoolPointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicBoolInitialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicBoolLoad(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicBoolStore(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicBoolExchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicBoolCompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicBoolCompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicBoolCompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicBoolCompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicBoolFetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicBoolFetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicBoolFetchXor(self, value, order)
    }
}

// MARK: - Int -

extension AtomicIntPointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicIntInitialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntLoad(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicIntStore(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntExchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicIntCompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicIntCompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicIntCompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicIntCompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntFetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntFetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntFetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntFetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicIntFetchSub(self, value, order)
    }
}

// MARK: - Int8 -

extension AtomicInt8Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicInt8Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicInt8Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt8CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt8CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt8CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt8CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt8FetchSub(self, value, order)
    }
}

// MARK: - Int16 -

extension AtomicInt16Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicInt16Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicInt16Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt16CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt16CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt16CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt16CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt16FetchSub(self, value, order)
    }
}

// MARK: - Int32 -

extension AtomicInt32Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicInt32Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicInt32Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt32CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt32CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt32CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt32CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt32FetchSub(self, value, order)
    }
}

// MARK: - Int64 -

extension AtomicInt64Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicInt64Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicInt64Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt64CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt64CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicInt64CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicInt64CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicInt64FetchSub(self, value, order)
    }
}

// MARK: - UInt -

extension AtomicUIntPointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicUIntInitialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntLoad(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicUIntStore(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntExchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUIntCompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUIntCompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUIntCompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUIntCompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntFetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntFetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntFetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntFetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUIntFetchSub(self, value, order)
    }
}

// MARK: - UInt8 -

extension AtomicUInt8Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicUInt8Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicUInt8Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt8CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt8CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt8CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt8CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt8FetchSub(self, value, order)
    }
}

// MARK: - UInt16 -

extension AtomicUInt16Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicUInt16Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicUInt16Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt16CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt16CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt16CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt16CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt16FetchSub(self, value, order)
    }
}

// MARK: - UInt32 -

extension AtomicUInt32Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicUInt32Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicUInt32Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt32CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt32CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt32CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt32CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt32FetchSub(self, value, order)
    }
}

// MARK: - UInt64 -

extension AtomicUInt64Pointer {
    @_transparent
    public func initialize(to initialValue: Pointee) {
        CAtomicUInt64Initialize(self, initialValue)
    }

    /// Atomically loads and returns the current value of the atomic variable
    /// pointed to by the receiver. The operation is atomic *read* operation.
    ///
    /// - Parameters:
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value stored in the receiver.
    @_transparent
    public func load(order: AtomicLoadMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64Load(self, order)
    }

    /// Atomically replaces the value of the atomic variable pointed to by the
    /// receiver with `desired`. The operation is atomic *write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    @_transparent
    public func store(_ desired: Pointee, order: AtomicStoreMemoryOrder = .seqcst) {
        CAtomicUInt64Store(self, desired, order)
    }

    /// Atomically replaces the value pointed by the receiver with `desired`
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - desired: The value to replace the receiver with.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    public func exchange(_ desired: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64Exchange(self, desired, order)
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt64CompareExchangeStrong(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchange(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt64CompareExchangeStrong(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The result of the comparison: `true` if current value was
    ///     equal to `*expected`, `false` otherwise.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: UnsafeMutablePointer<Pointee>,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Bool {
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        return CAtomicUInt64CompareExchangeWeak(
            self, expected, desired, order, loadOrder
        )
    }

    /// Atomically compares the value pointed to by the receiver with the
    /// value pointed to by `expected`, and if those are equal, replaces the
    /// former with `desired` (performs *read-modify-write* operation).
    /// Otherwise, loads the actual value pointed to by the receiver into
    /// `*expected` (performs *load* operation).
    ///
    /// This form of compare-and-exchange is allowed to fail spuriously, that
    /// is, act as if `*current != *expected` even if they are equal. When a
    /// compare-and-exchange is in a loop, this version will yield better
    /// performance on some platforms. When a weak compare-and-exchange would
    /// require a loop and a strong one would not, the strong one is preferable.
    ///
    /// - Parameters:
    ///     - expected: The value expected to be found in the receiver.
    ///     - desired: The value to store in the receiver if it is as expected.
    ///     - order: The memory synchronization ordering for the read-modify-write
    ///       operation if the comparison succeeds.
    ///     - loadOrder: The memory synchronization ordering for the load
    ///       operation if the comparison fails. Cannot specify stronger
    ///       ordering than `order`.
    ///
    /// - Returns: The value actually stored in the receiver. If exchange
    ///     succeeded, this will be equal to `expected`.
    @_transparent
    @discardableResult
    public func compareExchangeWeak(
        _ expected: Pointee,
        _ desired: Pointee,
        order: AtomicMemoryOrder = .seqcst,
        loadOrder: AtomicLoadMemoryOrder? = nil
    ) -> Pointee {
        var current = expected
        let loadOrder = loadOrder ?? order.strongestLoadOrder()
        _ = CAtomicUInt64CompareExchangeWeak(
            self, &current, desired, order, loadOrder
        )
        return current
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `AND` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `AND` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAnd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64FetchAnd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `OR` between the old value of the receiver and `value`, and
    /// returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `OR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchOr(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64FetchOr(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of bitwise `XOR` between the old value of the receiver and `value`,
    /// and returns the value the receiver held previously. The operation is
    /// *read-modify-write* operation.
    ///
    /// - Parameters:
    ///     - value: The value to bitwise `XOR` to the value stored in the
    ///       receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchXor(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64FetchXor(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of addition of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s
    /// complement representation. There are no undefined results. For pointer
    /// types, the result may be an undefined address, but the operations
    /// otherwise have no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to add to the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchAdd(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64FetchAdd(self, value, order)
    }

    /// Atomically replaces the value pointed by the receiver with the result
    /// of subtraction of `value` to the old value of the receiver, and returns
    /// the value the receiver held previously. The operation is *read-modify-write*
    /// operation.
    ///
    /// For signed integer types, arithmetic is defined to use two’s complement
    /// representation. There are no undefined results. For pointer types, the
    /// result may be an undefined address, but the operations otherwise have
    /// no undefined behavior.
    ///
    /// - Parameters:
    ///     - value: The value to subtract from the value stored in the receiver.
    ///     - order: The memory synchronization ordering for this operation.
    ///
    /// - Returns: The value previously stored in the receiver.
    @_transparent
    @discardableResult
    public func fetchSub(_ value: Pointee, order: AtomicMemoryOrder = .seqcst) -> Pointee {
        return CAtomicUInt64FetchSub(self, value, order)
    }
}
