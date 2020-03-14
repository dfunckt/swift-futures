//
//  CAtomic.h
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. All rights reserved.
//

#ifndef CAtomic_h
#define CAtomic_h

#if !__has_include(<stdatomic.h>) || !__has_extension(c_atomic)
#error Compiler does not offer required support for atomics
#endif

#include <stdlib.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <assert.h>

#if __has_attribute(__always_inline__)
#define _CATOMIC_INLINE static inline __attribute__((__always_inline__))
#else
#define _CATOMIC_INLINE static inline
#endif

#if __has_attribute(swift_name)
#define SWIFT_NAME(_name) __attribute__((swift_name(#_name)))
#else
#define SWIFT_NAME(_name)
#endif

#if !defined(SWIFT_ENUM)
#define SWIFT_ENUM(_type, _name) enum _name
#endif
#define _CATOMIC_ENUM(_type, _name) SWIFT_ENUM(_type, _name)

// MARK: -

_CATOMIC_ENUM(unsigned int, AtomicMemoryOrder) {
    /// Relaxed operation: there are no synchronization or ordering constraints
    /// imposed on other reads or writes, only this operation's atomicity is
    /// guaranteed.
    AtomicMemoryOrderRelaxed = memory_order_relaxed,

    /// A load operation with this memory order performs a consume operation
    /// on the affected memory location: no reads or writes in the current
    /// thread dependent on the value currently loaded can be reordered before
    /// this load. Writes to data-dependent variables in other threads that
    /// release the same atomic variable are visible in the current thread.
    /// On most platforms, this affects compiler optimizations only.
    AtomicMemoryOrderConsume = memory_order_consume,

    /// A load operation with this memory order performs the acquire operation
    /// on the affected memory location: no reads or writes in the current
    /// thread can be reordered before this load. All writes in other threads
    /// that release the same atomic variable are visible in the current thread.
    AtomicMemoryOrderAcquire = memory_order_acquire,

    /// A store operation with this memory order performs the release operation:
    /// no reads or writes in the current thread can be reordered after this
    /// store. All writes in the current thread are visible in other threads
    /// that acquire the same atomic variable and writes that carry a dependency
    /// into the atomic variable become visible in other threads that consume
    /// the same atomic.
    AtomicMemoryOrderRelease = memory_order_release,

    /// A read-modify-write operation with this memory order is both an acquire
    /// operation and a release operation. No memory reads or writes in the
    /// current thread can be reordered before or after this store. All writes
    /// in other threads that release the same atomic variable are visible
    /// before the modification and the modification is visible in other threads
    /// that acquire the same atomic variable.
    AtomicMemoryOrderAcqrel = memory_order_acq_rel,

    /// A load operation with this memory order performs an acquire operation,
    /// a store performs a release operation, and read-modify-write performs
    /// both an acquire operation and a release operation, plus a single total
    /// order exists in which all threads observe all modifications in the same
    /// order.
    AtomicMemoryOrderSeqcst = memory_order_seq_cst,
};

_CATOMIC_ENUM(unsigned int, AtomicLoadMemoryOrder) {
    /// Relaxed operation: there are no synchronization or ordering constraints
    /// imposed on other reads or writes, only this operation's atomicity is
    /// guaranteed.
    AtomicLoadMemoryOrderRelaxed = memory_order_relaxed,

    /// A load operation with this memory order performs a consume operation
    /// on the affected memory location: no reads or writes in the current
    /// thread dependent on the value currently loaded can be reordered before
    /// this load. Writes to data-dependent variables in other threads that
    /// release the same atomic variable are visible in the current thread.
    /// On most platforms, this affects compiler optimizations only.
    AtomicLoadMemoryOrderConsume = memory_order_consume,

    /// A load operation with this memory order performs the acquire operation
    /// on the affected memory location: no reads or writes in the current
    /// thread can be reordered before this load. All writes in other threads
    /// that release the same atomic variable are visible in the current thread.
    AtomicLoadMemoryOrderAcquire = memory_order_acquire,

    /// A load operation with this memory order performs an acquire operation,
    /// a store performs a release operation, and read-modify-write performs
    /// both an acquire operation and a release operation, plus a single total
    /// order exists in which all threads observe all modifications in the same
    /// order.
    AtomicLoadMemoryOrderSeqcst = memory_order_seq_cst,
};

_CATOMIC_ENUM(unsigned int, AtomicStoreMemoryOrder) {
    /// Relaxed operation: there are no synchronization or ordering constraints
    /// imposed on other reads or writes, only this operation's atomicity is
    /// guaranteed.
    AtomicStoreMemoryOrderRelaxed = memory_order_relaxed,

    /// A load operation with this memory order performs a consume operation
    /// on the affected memory location: no reads or writes in the current
    /// thread dependent on the value currently loaded can be reordered before
    /// this load. Writes to data-dependent variables in other threads that
    /// release the same atomic variable are visible in the current thread.
    /// On most platforms, this affects compiler optimizations only.
    AtomicStoreMemoryOrderConsume = memory_order_consume,

    /// A store operation with this memory order performs the release operation:
    /// no reads or writes in the current thread can be reordered after this
    /// store. All writes in the current thread are visible in other threads
    /// that acquire the same atomic variable and writes that carry a dependency
    /// into the atomic variable become visible in other threads that consume
    /// the same atomic.
    AtomicStoreMemoryOrderRelease = memory_order_release,

    /// A load operation with this memory order performs an acquire operation,
    /// a store performs a release operation, and read-modify-write performs
    /// both an acquire operation and a release operation, plus a single total
    /// order exists in which all threads observe all modifications in the same
    /// order.
    AtomicStoreMemoryOrderSeqcst = memory_order_seq_cst,
};

_CATOMIC_INLINE SWIFT_NAME(AtomicMemoryOrder.strongestLoadOrder(self:))
enum AtomicLoadMemoryOrder AtomicMemoryOrderStrongestLoadOrder(enum AtomicMemoryOrder self) {
    switch (self) {
        case AtomicMemoryOrderRelaxed:
            return AtomicLoadMemoryOrderRelaxed;
        case AtomicMemoryOrderConsume:
            return AtomicLoadMemoryOrderConsume;
        case AtomicMemoryOrderAcquire:
            return AtomicLoadMemoryOrderAcquire;
        case AtomicMemoryOrderRelease:
            return AtomicLoadMemoryOrderRelaxed;
        case AtomicMemoryOrderAcqrel:
            return AtomicLoadMemoryOrderAcquire;
        case AtomicMemoryOrderSeqcst:
            return AtomicLoadMemoryOrderSeqcst;
        default:
            return AtomicLoadMemoryOrderSeqcst;
    }
}

// MARK: -

_CATOMIC_INLINE void CAtomicThreadFence(enum AtomicMemoryOrder order) {
    atomic_thread_fence(order);
}

_CATOMIC_INLINE void CAtomicSignalFence(enum AtomicMemoryOrder order) {
    atomic_signal_fence(order);
}

_CATOMIC_INLINE void CAtomicHardwarePause() {
#if defined(__x86_64__) || defined(__i386__)
    __asm__("pause");
#elif defined(__arm64__) || (defined(__arm__) && defined(_ARM_ARCH_7) && defined(__thumb__))
    __asm__("yield");
#else
    __asm__("");
#endif
}

#if __has_include(<mach/thread_switch.h>)
#include <mach/thread_switch.h>
_CATOMIC_INLINE void CAtomicPreemptionYield(uint64_t timeout) {
    thread_switch(MACH_PORT_NULL, SWITCH_OPTION_DEPRESS, (mach_msg_timeout_t)timeout);
}
#else
#include <pthread.h>
_CATOMIC_INLINE void CAtomicPreemptionYield(uint64_t timeout) {
    sched_yield();
}
#endif

// MARK: -

#define _CATOMIC_VAR(name, swift_type, atomic_type, c_type) \
typedef volatile c_type C##name; \
typedef volatile c_type *_Nonnull name##Pointer; \
_CATOMIC_INLINE \
void C##name##Initialize(name##Pointer ptr, c_type value) { \
    atomic_init((atomic_type *)ptr, value); \
} \
_CATOMIC_INLINE \
_Bool C##name##CompareExchangeStrong(name##Pointer ptr, c_type *_Nonnull expected, c_type desired, enum AtomicMemoryOrder succ, enum AtomicLoadMemoryOrder fail) { \
    assert(((enum AtomicMemoryOrder)fail) <= succ); \
    return atomic_compare_exchange_strong_explicit((atomic_type *)ptr, expected, desired, succ, fail); \
} \
_CATOMIC_INLINE \
_Bool C##name##CompareExchangeWeak(name##Pointer ptr, c_type *_Nonnull expected, c_type desired, enum AtomicMemoryOrder succ, enum AtomicLoadMemoryOrder fail) { \
    assert(((enum AtomicMemoryOrder)fail) <= succ); \
    return atomic_compare_exchange_weak_explicit((atomic_type *)ptr, expected, desired, succ, fail); \
} \
_CATOMIC_INLINE \
c_type C##name##Exchange(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_exchange_explicit((atomic_type *)ptr, value, order); \
} \
_CATOMIC_INLINE \
c_type C##name##Load(name##Pointer ptr, enum AtomicLoadMemoryOrder order) { \
    return atomic_load_explicit((atomic_type *)ptr, order); \
} \
_CATOMIC_INLINE \
void C##name##Store(name##Pointer ptr, c_type value, enum AtomicStoreMemoryOrder order) { \
    atomic_store_explicit((atomic_type *)ptr, value, order); \
} \
_CATOMIC_INLINE \
c_type C##name##FetchAnd(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_fetch_and_explicit((atomic_type *)ptr, value, order); \
} \
_CATOMIC_INLINE \
c_type C##name##FetchOr(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_fetch_or_explicit((atomic_type *)ptr, value, order); \
} \
_CATOMIC_INLINE \
c_type C##name##FetchXor(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_fetch_xor_explicit((atomic_type *)ptr, value, order); \
}

#define _CATOMIC_INTEGER(name, swift_type, atomic_type, c_type) \
_CATOMIC_VAR(name, swift_type, atomic_type, c_type) \
_CATOMIC_INLINE \
c_type C##name##FetchAdd(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_fetch_add_explicit((atomic_type *)ptr, value, order); \
} \
_CATOMIC_INLINE \
c_type C##name##FetchSub(name##Pointer ptr, c_type value, enum AtomicMemoryOrder order) { \
    return atomic_fetch_sub_explicit((atomic_type *)ptr, value, order); \
}

_CATOMIC_VAR(AtomicBool, Bool, atomic_bool, _Bool);
_CATOMIC_INTEGER(AtomicInt, Int, atomic_long, long);
_CATOMIC_INTEGER(AtomicInt8, Int8, atomic_schar, signed char);
_CATOMIC_INTEGER(AtomicInt16, Int16, atomic_short, short);
_CATOMIC_INTEGER(AtomicInt32, Int32, atomic_int, int);
_CATOMIC_INTEGER(AtomicInt64, Int64, atomic_llong, long long);
_CATOMIC_INTEGER(AtomicUInt, UInt, atomic_ulong, unsigned long);
_CATOMIC_INTEGER(AtomicUInt8, UInt8, atomic_uchar, unsigned char);
_CATOMIC_INTEGER(AtomicUInt16, UInt16, atomic_ushort, unsigned short);
_CATOMIC_INTEGER(AtomicUInt32, UInt32, atomic_uint, unsigned int);
_CATOMIC_INTEGER(AtomicUInt64, UInt64, atomic_ullong, unsigned long long);

#endif /* CAtomic_h */
