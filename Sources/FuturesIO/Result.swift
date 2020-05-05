//
//  Result.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesPlatform

public typealias IOResult<T> = Result<T, IOError>

extension Result where Failure == IOError {
    @_transparent
    public init(catching body: () throws -> Success) {
        do {
            self = .success(try body())
        } catch let error as IOError {
            self = .failure(error)
        } catch {
            fatalError("expected IOError; got \(type(of: error))")
        }
    }
}

extension Result where Failure == IOError, Success: BinaryInteger {
    @_transparent
    @discardableResult
    public static func syscall(_ call: @autoclosure () -> Success) throws -> Success {
        return try self.init(syscall: call()).get()
    }

    // `@inline(never)` ensures errno is captured correctly and no ARC
    // traffic can happen inbetween that *could* change the errno value
    // before we are able to read it.
    @inline(never)
    public init(syscall call: @autoclosure () -> Success) {
        let result = call()
        if result == -1 {
            self = .failure(IOError.current())
        } else {
            self = .success(result)
        }
    }
}

extension Result where Failure == IOError, Success: BinaryInteger {
    @_transparent
    @discardableResult
    public static func uninterruptibleSyscall(_ call: @autoclosure () -> Success) throws -> Success {
        return try self.init(uninterruptibleSyscall: call()).get()
    }

    @_transparent
    public init(uninterruptibleSyscall call: @autoclosure () -> Success) {
        var result: IOResult<Success>
        retry: do {
            result = IOResult(syscall: call())
            if case .failure(EINTR) = result {
                continue retry
            }
        }
        self = result
    }
}
