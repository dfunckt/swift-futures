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
public let COMMON_MODES = CFRunLoopMode.commonModes! // swiftlint:disable:this force_unwrapping
#else
/// :nodoc:
public let COMMON_MODES = kCFRunLoopCommonModes! // swiftlint:disable:this force_unwrapping
#endif

public func assertOnRunLoopExecutor(_ executor: RunLoopExecutor) {
    assert(CFRunLoopGetCurrent() === executor._waker._runLoop)
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
    }

    public let label: String
    public let capacity: Int

    private let _runner: _TaskRunner
    fileprivate let _waker: _Waker

    public init(
        label: String? = nil,
        runLoop: CFRunLoop,
        mode: CFRunLoopMode = COMMON_MODES,
        capacity: Int = .max
    ) {
        let label = "futures.runloop-executor(\(label ?? _pointerAddressForDisplay(runLoop)))"
        self.label = label
        self.capacity = capacity
        _runner = .init(label: label)
        _waker = .init(runLoop, mode)
        _waker.setSignalHandler { [weak self] in self?._run() }
        _waker.activate()
    }

    deinit {
        _waker.cancel()
    }

    @usableFromInline
    @discardableResult
    func _run() -> Bool {
        var context = Context(runner: _runner, waker: _waker)
        return _runner.run(&context)
    }

    public func trySubmit<F: FutureProtocol>(_ future: F) -> Result<Void, Failure> where F.Output == Void {
        if _runner.count == capacity {
            return .failure(.atCapacity)
        }
        _runner.schedule(future)
        _waker.signal()
        return .success(())
    }
}

// MARK: Default executors

extension RunLoopExecutor {
    private static let _current = _ThreadLocal<RunLoopExecutor>()

    public static var current: RunLoopExecutor {
        if let executor = _current.value {
            return executor
        }
        let executor: RunLoopExecutor
        if CFRunLoopGetMain() === CFRunLoopGetCurrent() {
            executor = .main
        } else {
            executor = RunLoopExecutor(runLoop: CFRunLoopGetCurrent())
        }
        _current.value = executor
        return executor
    }

    public static let main = RunLoopExecutor(
        label: "main",
        runLoop: CFRunLoopGetMain(),
        mode: COMMON_MODES
    )
}

// MARK: - Private -

private final class _Waker: WakerProtocol {
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

    init(_ runLoop: CFRunLoop, _ mode: CFRunLoopMode) {
        _runLoop = runLoop
        _mode = mode
    }

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

    func activate() {
        CFRunLoopAddSource(_runLoop, _source, _mode)
    }

    func cancel() {
        _signalled.store(true)
        CFRunLoopSourceInvalidate(_source)
    }

    func signal() {
        if _signalled.exchange(true) {
            return
        }
        CFRunLoopSourceSignal(_source)
        CFRunLoopWakeUp(_runLoop)
    }
}
