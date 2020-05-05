//
//  FileDescriptor.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesIO
import FuturesPlatform

public struct FileDescriptor: RawRepresentable {
    public let rawValue: CInt

    @inlinable
    public init(rawValue: CInt) {
        self.rawValue = rawValue
    }
}

extension FileDescriptor: Equatable {}

extension FileDescriptor: Hashable {}

extension FileDescriptor {
    public static let standardInput = FileDescriptor(rawValue: STDIN_FILENO)
    public static let standardOutput = FileDescriptor(rawValue: STDOUT_FILENO)
    public static let standardError = FileDescriptor(rawValue: STDERR_FILENO)
}

extension FileDescriptor {
    @inlinable
    public func close() {
        // Note that errors are ignored when closing a file descriptor. The
        // reason for this is that if an error occurs, we don't actually know
        // if the file descriptor was closed or not, and if we retried (for
        // something like EINTR), we might close another valid file descriptor
        // opened after we closed ours.
        _ = FuturesPlatform.close(rawValue)
    }

    /// - Throws: `IOError` with any of the following error codes:
    ///     - `EBADF` or `EINVAL` if the socket's file descriptor is invalid.
    ///     - `EMFILE` if the maximum allowed number of file descriptors are
    ///       currently open.
    @inlinable
    public func duplicate() throws -> FileDescriptor {
        try .init(rawValue: IOResult.syscall(fcntl(rawValue, F_DUPFD_CLOEXEC)))
    }
}

extension FileDescriptor {
    /// - Throws: `IOError` with code `EBADF` if the socket's file descriptor
    ///     is invalid.
    @inlinable
    public func shouldCloseOnExec() throws -> Bool {
        let currFlags = try IOResult.syscall(fcntl(rawValue, F_GETFD))
        return currFlags & FD_CLOEXEC != 0
    }

    /// - Throws: `IOError` with code `EBADF` if the socket's file descriptor
    ///     is invalid.
    @inlinable
    public func setShouldCloseOnExec(_ shouldClose: Bool) throws {
        let currFlags = try IOResult.syscall(fcntl(rawValue, F_GETFD))
        let newFlags = shouldClose
            ? currFlags | FD_CLOEXEC
            : currFlags ^ FD_CLOEXEC
        if newFlags != currFlags {
            try IOResult.syscall(fcntl(rawValue, F_SETFD, newFlags))
        }
    }

    /// - Throws: `IOError` with code `EBADF` if the socket's file descriptor
    ///     is invalid.
    @inlinable
    public func isNonBlocking() throws -> Bool {
        let currFlags = try IOResult.syscall(fcntl(rawValue, F_GETFL))
        return currFlags & O_NONBLOCK != 0
    }

    /// - Throws: `IOError` with code `EBADF` if the socket's file descriptor
    ///     is invalid.
    @inlinable
    public func setNonBlocking(_ shouldNotBlock: Bool) throws {
        let currFlags = try IOResult.syscall(fcntl(rawValue, F_GETFL))
        let newFlags = shouldNotBlock
            ? currFlags | O_NONBLOCK
            : currFlags ^ O_NONBLOCK
        if newFlags != currFlags {
            try IOResult.syscall(fcntl(rawValue, F_SETFL, newFlags))
        }
    }
}

extension FileDescriptor {
    @inlinable
    public func read(_ buffer: IOMutableBufferPointer) throws -> Int {
        let length = read_caplen(buffer.count)
        return try IOResult.syscall(
            FuturesPlatform.read(rawValue, buffer.baseAddress, length)
        )
    }

    @inlinable
    public func write(_ buffer: IOBufferPointer) throws -> Int {
        let length = read_caplen(buffer.count)
        return try IOResult.syscall(
            FuturesPlatform.write(rawValue, buffer.baseAddress, length)
        )
    }
}
