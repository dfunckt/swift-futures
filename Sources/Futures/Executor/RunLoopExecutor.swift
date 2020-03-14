//
//  RunLoopExecutor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import CoreFoundation
import FuturesSync

#if canImport(Darwin)
/// :nodoc:
public let COMMON_MODES = CFRunLoopMode.commonModes!
// swiftlint:disable:previous force_unwrapping
#else
/// :nodoc:
public let COMMON_MODES = kCFRunLoopCommonModes!
// swiftlint:disable:previous force_unwrapping
#endif

public func assertOnRunLoopExecutor(_ executor: RunLoopExecutor) {
    assert(CFRunLoopGetCurrent() === executor._scheduler.waker._runLoop)
}

public func assertOnMainRunLoopExecutor() {
    assertOnRunLoopExecutor(RunLoopExecutor.main)
}

public final class RunLoopExecutor: ExecutorProtocol {
    /// The type of errors this executor may return from `trySubmit(_:)`.
    ///
    /// It only defines one error case, for the executor being at capacity.
    public enum Failure: Error {
        /// Denotes that the executor is at capacity.
        ///
        /// This is a transient error; subsequent submissions may succeed.
        case atCapacity

        case shutdown
    }

    public let label: String

    @usableFromInline let _scheduler: SharedScheduler<Void, _RunLoopWaker>
    @usableFromInline let _capacity: Int

    @inlinable
    public init(
        label: String? = nil,
        runLoop: CFRunLoop,
        mode: CFRunLoopMode = COMMON_MODES,
        capacity: Int = .max
    ) {
        self.label = "futures.runloop-executor(\(label ?? pointerAddressForDisplay(runLoop)))"
        _capacity = capacity
        _scheduler = .init(waker: .init(runLoop, mode))
        _scheduler.waker.setSignalHandler { [weak self] in
            _ = self?._scheduler.run()
        }
        _scheduler.waker.activate()
    }

    deinit {
        _scheduler.waker.cancel()
    }

    @inlinable
    public func trySubmit<F: FutureProtocol>(_ future: F) -> Result<Void, Failure> where F.Output == Void {
        if _scheduler.count == _capacity {
            return .failure(.atCapacity)
        }
        _scheduler.submit(future)
        _scheduler.waker.signal()
        return .success(())
    }
}

// MARK: Default executors

@usableFromInline let _currentRunLoopExecutor = ThreadLocal<RunLoopExecutor> {
    // swiftlint:disable:next force_unwrapping
    let currentRunLoop = CFRunLoopGetCurrent()!
    if currentRunLoop === CFRunLoopGetMain() {
        return .main
    }
    return .init(runLoop: currentRunLoop)
}

extension RunLoopExecutor {
    @inlinable
    public static var current: RunLoopExecutor {
        _currentRunLoopExecutor.value
    }

    public static let main = RunLoopExecutor(
        label: "main",
        runLoop: CFRunLoopGetMain(),
        mode: COMMON_MODES
    )
}

// MARK: - Private -

@usableFromInline
final class _RunLoopWaker: WakerProtocol {
    private final class Callback {
        let handler: () -> Void

        init(_ fn: @escaping () -> Void) {
            handler = fn
        }
    }

    fileprivate let _runLoop: CFRunLoop
    private let _mode: CFRunLoopMode
    private var _source: CFRunLoopSource! // swiftlint:disable:this implicitly_unwrapped_optional
    private let _signalled = AtomicBool(false)

    @usableFromInline
    init(_ runLoop: CFRunLoop, _ mode: CFRunLoopMode) {
        _runLoop = runLoop
        _mode = mode
    }

    @usableFromInline
    func setSignalHandler(_ fn: @escaping () -> Void) {
        let callback = Callback { [_signalled, fn] in
            _signalled.store(false)
            fn()
        }
        _source = withExtendedLifetime(callback) {
            var context = CFRunLoopSourceContext()
            context.version = 0
            context.info = Unmanaged.passUnretained(callback).toOpaque()
            context.retain = { ptr in
                UnsafeRawPointer(
                    Unmanaged<Callback>
                        .fromOpaque(ptr!) // swiftlint:disable:this force_unwrapping
                        .retain()
                        .toOpaque()
                )
            }
            context.release = { ptr in
                Unmanaged<Callback>
                    .fromOpaque(ptr!) // swiftlint:disable:this force_unwrapping
                    .release()
            }
            context.perform = { ptr in
                Unmanaged<Callback>
                    .fromOpaque(ptr!) // swiftlint:disable:this force_unwrapping
                    .takeUnretainedValue()
                    .handler()
            }
            return CFRunLoopSourceCreate(nil, 0, &context)
        }
    }

    @usableFromInline
    func activate() {
        CFRunLoopAddSource(_runLoop, _source, _mode)
    }

    func cancel() {
        _signalled.store(true)
        CFRunLoopSourceInvalidate(_source)
    }

    @usableFromInline
    func signal() {
        if _signalled.exchange(true) {
            return
        }
        CFRunLoopSourceSignal(_source)
        CFRunLoopWakeUp(_runLoop)
    }
}
