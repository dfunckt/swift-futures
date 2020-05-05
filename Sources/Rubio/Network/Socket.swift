//
//  Socket.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesIO
import FuturesPlatform

public struct Socket {
    public let descriptor: FileDescriptor

    @inlinable
    public init(descriptor: FileDescriptor) {
        self.descriptor = descriptor
    }
}

extension Socket: RawRepresentable {
    public var rawValue: CInt {
        @_transparent get { descriptor.rawValue }
    }

    @_transparent
    public init(rawValue: CInt) {
        descriptor = .init(rawValue: rawValue)
    }
}

extension Socket {
    @inlinable
    public init(domain: CInt, type: CInt, nonBlocking: Bool = false) throws {
        #if os(Linux)
        let flags = type | SOCK_CLOEXEC | (nonBlocking ? SOCK_NONBLOCK : 0)
        #else
        let flags = type
        #endif

        let fd = try IOResult.syscall(socket(domain, flags, 0))

        #if !os(Linux)
        do {
            let extraFlags = O_CLOEXEC | (nonBlocking ? O_NONBLOCK : 0)
            try IOResult.syscall(fcntl(fd, F_SETFL, extraFlags))
            try IOResult.syscall(setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, enabled: true))
        } catch {
            _ = FuturesPlatform.close(fd)
            throw error
        }
        #endif

        self.init(rawValue: fd)
    }
}

extension Socket: Equatable {}

extension Socket: Hashable {}

// MARK: -

extension Socket {
    @inlinable
    public func close() {
        descriptor.close()
    }
}

extension Socket {
    /// - Throws: `IOError`. See `FileDescriptor.duplicate()`
    @inlinable
    public func duplicate() throws -> Socket {
        try .init(descriptor: descriptor.duplicate())
    }
}

// MARK: -

extension Socket {
    public enum Shutdown {
        case read
        case write
        case both
    }

    /// Shut down part of a full-duplex connection.
    ///
    /// This method causes all or part of a full-duplex connection on the
    /// socket to be shut down. If `how` is `Shutdown.read`, further receives
    /// will be disallowed. If `how` is `Shutdown.write`, further sends will
    /// be disallowed. If `how` is `Shutdown.both`, further sends and receives
    /// will be disallowed.
    ///
    /// - Throws: `IOError` with code `EBADF` or `ENOTSOCK` if the socket's
    ///     file descriptor is invalid.
    @inlinable
    public func shutdown(_ how: Shutdown) throws {
        do {
            try IOResult.syscall(
                FuturesPlatform.shutdown(rawValue, how.rawValue)
            )
        } catch let error as IOError where error.code == ENOTCONN {
            // Darwin fails with ENOTCONN if called a second time, but we
            // normalize this call into an idempotent one, like on Linux.
        }
    }
}

extension Socket.Shutdown: RawRepresentable {
    public var rawValue: CInt {
        @_transparent get {
            switch self {
            case .read:
                return SHUT_RD
            case .write:
                return SHUT_WR
            case .both:
                return SHUT_RDWR
            }
        }
    }

    @_transparent
    public init?(rawValue: CInt) {
        switch rawValue {
        case SHUT_RD:
            self = .read
        case SHUT_WR:
            self = .write
        case SHUT_RDWR:
            self = .both
        default:
            return nil
        }
    }
}

// MARK: -

extension Socket {
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EINVAL` if the option is invalid at the level indicated.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `ENOMEM` if there were insufficient memory available in the
    ///         system to perform the operation.
    ///     - `ENOPROTOOPT` if the option is unknown at the level indicated.
    @inlinable
    public func getOption<T>(_ name: CInt, of level: CInt = SOL_SOCKET) throws -> T? {
        assert(T.self != Bool.self, "use 'getFlag(_:of:)' for boolean options")
        var outValue: T?
        try IOResult.syscall(getsockopt(rawValue, level, name, &outValue))
        return outValue
    }

    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EDOM` if `newValue` is out of bounds for the option.
    ///     - `EINVAL` if the option is invalid at the level indicated or the
    ///         socket has been shut down.
    ///     - `EISCONN` if the socket is already connected and a specified
    ///         option cannot be set while this is the case.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `ENOMEM` if there were insufficient memory available in the
    ///         system to perform the operation.
    ///     - `ENOPROTOOPT` if the option is unknown at the level indicated.
    @inlinable
    public func setOption<T>(_ name: CInt, of level: CInt = SOL_SOCKET, to newValue: T) throws {
        assert(T.self != Bool.self, "use 'setFlag(_:of:to:)' for boolean options")
        try IOResult.syscall(setsockopt(rawValue, level, name, newValue))
    }

    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EINVAL` if the option is invalid at the level indicated.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `ENOMEM` if there were insufficient memory available in the
    ///         system to perform the operation.
    ///     - `ENOPROTOOPT` if the option is unknown at the level indicated.
    @inlinable
    public func getFlag(_ name: CInt, of level: CInt = SOL_SOCKET) throws -> Bool? {
        var outValue: Bool?
        try IOResult.syscall(getsockopt(rawValue, level, name, enabled: &outValue))
        return outValue
    }

    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EDOM` if `newValue` is out of bounds for the option.
    ///     - `EINVAL` if the option is invalid at the level indicated or the
    ///         socket has been shut down.
    ///     - `EISCONN` if the socket is already connected and a specified
    ///         option cannot be set while this is the case.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `ENOMEM` if there were insufficient memory available in the
    ///         system to perform the operation.
    ///     - `ENOPROTOOPT` if the option is unknown at the level indicated.
    @inlinable
    public func setFlag(_ name: CInt, of level: CInt = SOL_SOCKET, to newValue: Bool) throws {
        try setOption(name, of: level, to: newValue)
    }
}

// MARK: -

extension Socket {
    /// - Throws: `IOError`. See `getOption(_:of:)`.
    @inlinable
    public func timeout(for kind: CInt) throws -> Duration? {
        if let tv = try getOption(kind) as timeval? {
            return .init(tv)
        }
        return nil
    }

    /// - Throws: `IOError`. See `setOption(_:of:to:)`.
    @inlinable
    public func setTimeout(_ duration: Duration?, for kind: CInt) throws {
        let duration = duration ?? 0
        try setOption(kind, to: duration.timeval)
    }

    /// - Throws: `IOError`. See `FileDescriptor.shouldCloseOnExec()`.
    @inlinable
    public func shouldCloseOnExec() throws -> Bool {
        try descriptor.shouldCloseOnExec()
    }

    /// - Throws: `IOError`. See `FileDescriptor.setShouldCloseOnExec(_:)`.
    @inlinable
    public func setShouldCloseOnExec(_ shouldClose: Bool) throws {
        try descriptor.setShouldCloseOnExec(shouldClose)
    }

    /// - Throws: `IOError`. See `FileDescriptor.isNonBlocking()`.
    @inlinable
    public func isNonBlocking() throws -> Bool {
        try descriptor.isNonBlocking()
    }

    /// - Throws: `IOError`. See `FileDescriptor.setNonBlocking(_:)`.
    @inlinable
    public func setNonBlocking(_ shouldNotBlock: Bool) throws {
        try descriptor.setNonBlocking(shouldNotBlock)
    }
}

// MARK: -

extension Socket {
    /// - Throws: `IOError`. See `setFlag(_:of:to:)`.
    @inlinable
    public func setNoDelay(_ shouldNotDelay: Bool) throws {
        try setFlag(TCP_NODELAY, of: IPPROTO_TCP, to: shouldNotDelay)
    }

    /// - Throws: `IOError`. See `setOption(_:of:to:)`.
    @inlinable
    public func setHopLimit(_ maxHopCount: UInt8) throws {
        try setOption(IP_TTL, of: IPPROTO_IP, to: maxHopCount)
    }
}

// MARK: -

extension Socket {
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EINVAL` if the socket has been shut down.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `EOPNOTSUPP` if the protocol in use by this socket does not
    ///         support `getsockname()`.
    @inlinable
    public func localAddress(_ address: inout SocketAddressStorage) throws {
        try address.withUnsafeMutablePointerToRawValue {
            _ = try IOResult.syscall(getsockname(rawValue, $0, $1))
        }
    }

    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EINVAL` if the socket has been shut down.
    ///     - `ENOBUFS` if there were insufficient resources available in the
    ///         system to perform the operation.
    ///     - `ENOTCONN` if the socket is not connected or it has not had the
    ///         peer pre-specified.
    ///     - `EOPNOTSUPP` if the protocol in use by this socket does not
    ///         support `getpeername()`.
    @inlinable
    public func peerAddress(_ address: inout SocketAddressStorage) throws {
        try address.withUnsafeMutablePointerToRawValue {
            _ = try IOResult.syscall(getpeername(rawValue, $0, $1))
        }
    }
}

extension Socket {
    /// Initiate a connection on this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EACCES` if the destination address is a broadcast address and
    ///         the socket option SO_BROADCAST is not set.
    ///     - `EADDRINUSE` if the address is already in use.
    ///     - `EADDRNOTAVAIL` if the specified address is not available on
    ///         this machine.
    ///     - `EAFNOSUPPORT` if addresses in the specified address family
    ///         cannot be used with this socket.
    ///     - `EALREADY` if the socket is non-blocking and a previous
    ///         connection attempt has not yet been completed.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNREFUSED` if the attempt to connect was ignored (because
    ///         the target is not listening for connections) or explicitly
    ///         rejected.
    ///     - `ECONNRESET` if the remote host reset the connection request.
    ///     - `EHOSTUNREACH` if the target host cannot be reached (e.g., down,
    ///         disconnected).
    ///     - `EINPROGRESS` if the socket is non-blocking and the connection
    ///         cannot be completed immediately.
    ///     - `EINVAL` if an invalid argument was detected (e.g., socket
    ///         address length is not valid for the address family, the
    ///         specified address family is invalid).
    ///     - `EISCONN` if the socket is already connected.
    ///     - `ENETDOWN` if the local network interface is not functioning.
    ///     - `ENETUNREACH` if the network isn't reachable from this host.
    ///     - `ENOBUFS` if the system call was unable to allocate a needed
    ///         memory buffer.
    ///     - `EOPNOTSUPP` if the socket is listening, therefore no connection
    ///         is allowed.
    ///     - `EPROTOTYPE` if the address has a different type than the socket
    ///         that is bound to the specified peer address.
    ///     - `ETIMEDOUT` if connection establishment timed out without
    ///         establishing a connection.
    ///
    ///     The following additional error codes apply specifically to UNIX
    ///     domain sockets:
    ///
    ///     - `EACCES` if search permission is denied for a component of the
    ///         path prefix, or write access to the named socket is denied.
    ///     - `EIO` if an I/O error occurred while reading from or writing to
    ///         the file system.
    ///     - `ELOOP` if too many symbolic links were encountered in
    ///         translating the pathname. This is taken to be indicative of a
    ///         looping symbolic link.
    ///     - `ENAMETOOLONG` if a component of a pathname exceeded `{NAME_MAX}`
    ///         characters, or an entire path name exceeded `{PATH_MAX}`
    ///         characters.
    ///     - `ENOENT` if the named socket does not exist.
    ///     - `ENOTDIR` if a component of the path prefix is not a directory.
    @inlinable
    public func connect<S: SocketAddressProtocol>(address: S) throws {
        try address.withUnsafePointerToRawValue {
            _ = try IOResult.uninterruptibleSyscall(
                FuturesPlatform.connect(rawValue, $0, $1)
            )
        }
    }

    /// Bind a name to this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EACCES` if the requested address is protected, and the current
    ///         user has inadequate permission to access it.
    ///     - `EADDRINUSE` if the specified address is already in use.
    ///     - `EADDRNOTAVAIL` if the specified address is not available from
    ///         the local machine.
    ///     - `EAFNOSUPPORT` if address is not valid for the address family
    ///         of socket.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EINVAL` if the socket is already bound to an address and the
    ///         protocol does not support binding to a new address.
    ///         Alternatively, socket may have been shut down.
    ///     - `EOPNOTSUPP` if the socket is not of a type that can be bound
    ///         to an address.
    ///
    ///     The following additional error codes apply specifically to UNIX
    ///     domain sockets:
    ///
    ///     - `EACCES` if a component of the path prefix does not allow
    ///         searching or the node's parent directory denies write
    ///         permission.
    ///     - `EEXIST` if a file already exists at the pathname. unlink(2) it
    ///         first.
    ///     - `EIO` if an I/O error occurred while making the directory entry
    ///         or allocating the inode.
    ///     - `EISDIR` if an empty pathname was specified.
    ///     - `ELOOP` if too many symbolic links were encountered in
    ///         translating the pathname. This is taken to be indicative of a
    ///         looping symbolic link.
    ///     - `ENAMETOOLONG` if a component of a pathname exceeded `{NAME_MAX}`
    ///         characters, or an entire path name exceeded `{PATH_MAX}`
    ///         characters.
    ///     - `ENOENT` if a component of the path name does not refer to an
    ///         existing file.
    ///     - `ENOTDIR` if a component of the path prefix is not a directory.
    ///     - `EROFS` if the name would reside on a read-only file system.
    @inlinable
    public func bind<S: SocketAddressProtocol>(address: S) throws {
        try address.withUnsafePointerToRawValue {
            _ = try IOResult.syscall(
                FuturesPlatform.bind(rawValue, $0, $1)
            )
        }
    }

    /// Listen for connections on this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EACCES` if the current process has insufficient privileges.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `EDESTADDRREQ` if the socket is not bound to a local address and
    ///         the protocol does not support listening on an unbound socket.
    ///     - `EINVAL` if the socket is already connected.
    ///     - `EOPNOTSUPP` if the socket is not of a type that supports `listen()`.
    @inlinable
    public func listen(backlog: CInt = 1_024) throws {
        try IOResult.syscall(FuturesPlatform.listen(rawValue, backlog))
    }

    /// Accept a connection on this socket.
    ///
    /// - Parameter nonBlocking: A boolean denoting whether to set the
    ///     accepted socket in non-blocking mode. On Darwin this flag is
    ///     inherited from the server socket, thus this parameter is ignored.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNABORTED` if the connection to socket has been aborted.
    ///     - `EINVAL` if the socket is unwilling to accept connections.
    ///     - `EMFILE` if the per-process descriptor table is full.
    ///     - `ENFILE` if the system file table is full.
    ///     - `ENOMEM` if insufficient memory was available to complete the
    ///         operation.
    ///     - `EOPNOTSUPP` if the socket is not of type `SOCK_STREAM` and thus
    ///         does not accept connections.
    ///     - `EWOULDBLOCK` if the socket is marked as non-blocking and no
    ///         connections are present to be accepted.
    @inlinable
    public func accept(nonBlocking: Bool = false) throws -> Socket {
        try _accept0(nonBlocking: nonBlocking, address: nil, length: nil)
    }

    /// Accept a connection on this socket.
    ///
    /// - Parameter nonBlocking: A boolean denoting whether to set the
    ///     accepted socket in non-blocking mode. On Darwin this flag is
    ///     inherited from the server socket, thus this parameter is ignored.
    ///
    /// - Parameter peerAddress: The address of the connecting entity, as
    ///     known to the communications layer.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNABORTED` if the connection to socket has been aborted.
    ///     - `EINVAL` if the socket is unwilling to accept connections.
    ///     - `EMFILE` if the per-process descriptor table is full.
    ///     - `ENFILE` if the system file table is full.
    ///     - `ENOMEM` if insufficient memory was available to complete the
    ///         operation.
    ///     - `EOPNOTSUPP` if the socket is not of type `SOCK_STREAM` and thus
    ///         does not accept connections.
    ///     - `EWOULDBLOCK` if the socket is marked as non-blocking and no
    ///         connections are present to be accepted.
    @inlinable
    public func accept(nonBlocking: Bool = false, peerAddress: inout SocketAddressStorage) throws -> Socket {
        try peerAddress.withUnsafeMutablePointerToRawValue {
            try _accept0(nonBlocking: nonBlocking, address: $0, length: $1)
        }
    }

    @inlinable
    func _accept0(
        nonBlocking: Bool,
        address: UnsafeMutablePointer<sockaddr>?,
        length: UnsafeMutablePointer<socklen_t>?
    ) throws -> Socket {
        #if os(Linux)
        // Use `accept4` on Linux, which accepts extra flags,
        // in order to minimize the number of syscalls.
        let flags = SOCK_CLOEXEC | (nonBlocking ? SOCK_NONBLOCK : 0)
        return Socket(rawValue: try IOResult.uninterruptibleSyscall(
            accept4(rawValue, address, length, flags)
        ))
        #else

        let socket = Socket(rawValue: try IOResult.uninterruptibleSyscall(
            FuturesPlatform.accept(rawValue, address, length)
        ))
        do {
            // On Darwin, sockets returned from `accept()` inherit the
            // non-blocking flag, so we only need to set CLOEXEC.
            try socket.setShouldCloseOnExec(true)
        } catch {
            socket.close()
            throw error
        }

        return socket
        #endif
    }
}

extension Socket {
    /// Send a message from this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EACCES` if the destination address is a broadcast address and
    ///         the socket option SO_BROADCAST is not set.
    ///     - `EADDRNOTAVAIL` if the specified address is not available on
    ///         this machine.
    ///     - `EAGAIN` if the socket is marked non-blocking and the requested
    ///         operation would block.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNRESET` if a connection is forcibly closed by a peer.
    ///     - `EDESTADDRREQ` if the socket is not connection-mode and no peer
    ///         address is set.
    ///     - `EHOSTUNREACH` if the target host cannot be reached (e.g., down,
    ///         disconnected).
    ///     - `EMSGSIZE` if the socket requires that message be sent atomically,
    ///         and the size of the message to be sent makes this impossible.
    ///     - `ENETDOWN` if the local network interface used to reach the
    ///         destination is down.
    ///     - `ENETUNREACH` if no route to the network is present.
    ///     - `ENOBUFS` if the output queue for a network interface is full.
    ///         This generally indicates that the interface has stopped sending,
    ///         but may be caused by transient congestion. Alternatively, if
    ///         the system is unable to allocate an internal buffer. The
    ///         operation may succeed when buffers become available.
    ///     - `ENOTCONN` if the socket is not connected or otherwise has not
    ///         had the peer pre-specified.
    ///     - `EPIPE` if the socket is shut down for writing or the socket is
    ///         connection-mode and is no longer connected.
    @inlinable
    public func send(_ buffer: IOBufferPointer) throws -> Int {
        #if !os(Linux)
        // Shim for Linux flag that suppresses SIGPIPE when the peer closes
        // the connection. This in undefined on Darwin and is not really
        // needed because we disable SIGPIPE on newly created sockets, and
        // sockets received from `accept()` inherit this flag. This is in
        // contrast to the behavior on Linux, where there's no socket-level
        // option to disable SIGPIPE.
        let MSG_NOSIGNAL: CInt = 0
        #endif
        let length = read_caplen(buffer.count)
        return try IOResult.syscall(
            FuturesPlatform.send(rawValue, buffer.baseAddress, length, MSG_NOSIGNAL)
        )
    }

    // TODO: sendmsg()
    // TODO: sendto()

    /// Receive a message from this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EAGAIN` if the socket is marked non-blocking, and the receive
    ///         operation would block, or a receive timeout had been set, and
    ///         the timeout expired before data were received.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNRESET` if the connection is closed by the peer during a
    ///         receive attempt on a socket.
    ///     - `ENOBUFS` if an attempt to allocate a memory buffer fails.
    ///     - `ENOTCONN` if the socket is associated with a connection-oriented
    ///         protocol and has not been connected. See `connect(_:)` and
    ///         `accept()`.
    ///     - `ETIMEDOUT` if the connection timed out.
    ///
    /// - Returns: The number of bytes received. For TCP sockets, the return
    ///     value 0 means the peer has closed its half side of the connection.
    @inlinable
    public func recv(_ buffer: IOMutableBufferPointer) throws -> Int {
        let length = read_caplen(buffer.count)
        return try IOResult.syscall(
            FuturesPlatform.recv(rawValue, buffer.baseAddress, length, 0)
        )
    }

    // TODO: recvmsg()
    // TODO: recvfrom()

    /// Peek at incoming message without removing that data from the receive
    /// queue of this socket.
    ///
    /// - Throws: `IOError` with any of the following error codes:
    ///
    ///     - `EAGAIN` if the socket is marked non-blocking, and the receive
    ///         operation would block, or a receive timeout had been set, and
    ///         the timeout expired before data were received.
    ///     - `EBADF` or `ENOTSOCK` if the socket's file descriptor is invalid.
    ///     - `ECONNRESET` if the connection is closed by the peer during a
    ///         receive attempt on a socket.
    ///     - `ENOBUFS` if an attempt to allocate a memory buffer fails.
    ///     - `ENOTCONN` if the socket is associated with a connection-oriented
    ///         protocol and has not been connected. See `connect(_:)` and
    ///         `accept()`.
    ///     - `ETIMEDOUT` if the connection timed out.
    @inlinable
    public func peek(_ buffer: IOMutableBufferPointer) throws -> Int {
        let length = read_caplen(buffer.count)
        return try IOResult.syscall(
            FuturesPlatform.recv(rawValue, buffer.baseAddress, length, MSG_PEEK)
        )
    }
}

// MARK: -

extension Socket: RawInputStream {
    @inlinable
    public func tryRead(into buffer: IOMutableBufferPointer) -> IOResult<Int> {
        return IOResult { try recv(buffer) }
    }
}

extension Socket: RawOutputStream {
    @inlinable
    public func tryWrite(from buffer: IOBufferPointer) -> IOResult<Int> {
        return IOResult { try send(buffer) }
    }

    @inlinable
    public func tryFlush() -> IOResult<Void> {
        return .success(())
    }

    @inlinable
    public func tryClose() -> IOResult<Void> {
        return .success(close())
    }
}
