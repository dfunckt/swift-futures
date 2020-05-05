//
//  Stream.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

public typealias IOBufferPointer = UnsafeRawBufferPointer
public typealias IOMutableBufferPointer = UnsafeMutableRawBufferPointer

// MARK: - Raw streams -

public protocol RawInputStream {
    /// Read from this stream into the given buffer.
    ///
    /// On success, returns the number of bytes read.
    func tryRead(into buffer: IOMutableBufferPointer) -> IOResult<Int>
}

public protocol RawOutputStream {
    /// Write from the given buffer into this stream.
    ///
    /// On success, returns the number of bytes written.
    func tryWrite(from buffer: IOBufferPointer) -> IOResult<Int>

    /// Flush the stream, ensuring that any buffered data reached their
    /// destination.
    func tryFlush() -> IOResult<Void>

    /// Close the stream.
    ///
    /// This method may be called multiple times, even after it returns
    /// `.success(())`.
    func tryClose() -> IOResult<Void>
}

public protocol SeekableRawStream {
    /// Seek to the given offset, in bytes, relative to the current position
    /// in the stream.
    ///
    /// On success, returns the new position from the start of the stream.
    ///
    /// Seeking with an offset of zero returns the stream's current position.
    /// Seeking beyond the end of a stream is allowed. Seeking before the start
    /// of the stream is considered an error.
    ///
    /// The behavior of seeking with a negative offset is freely defined by
    /// an implementation. For example, a stream wrapping an open file may
    /// seek towards the start of the file, but a stream wrapping a socket or
    /// a pipe may reject the call with an error of kind `ENOTSUP`.
    func trySeek(offset: Int64) -> IOResult<UInt64>
}

// MARK: - Asynchronous streams -

public protocol InputStream {
    /// Read from this stream into the given buffer.
    ///
    /// On success, returns the number of bytes read.
    ///
    /// If no data is available for reading, the method returns `Poll.pending`
    /// and arranges for the current task to receive a notification when the
    /// stream becomes readable or is closed.
    ///
    /// This function must not return errors of kind `EWOULDBLOCK` or `EINTR`.
    /// Implementations must convert `EWOULDBLOCK` into `Poll.pending` and
    /// either internally retry or convert `EINTR` into another error kind.
    mutating func pollRead(_ context: inout Context, into buffer: IOMutableBufferPointer) -> Poll<IOResult<Int>>
}

public protocol OutputStream {
    /// Write from the given buffer into this stream.
    ///
    /// On success, returns the number of bytes written.
    ///
    /// If the stream is not ready for writing, the method returns `Poll.pending`
    /// and arranges for the current task to receive a notification when the
    /// stream becomes writable or is closed.
    ///
    /// This function must not return errors of kind `EWOULDBLOCK` or `EINTR`.
    /// Implementations must convert `EWOULDBLOCK` into `Poll.pending` and
    /// either internally retry or convert `EINTR` into another error kind.
    mutating func pollWrite(_ context: inout Context, from buffer: IOBufferPointer) -> Poll<IOResult<Int>>

    /// Flush the stream, ensuring that any buffered data reached their
    /// destination.
    ///
    /// On success, returns `Poll.ready(.success(()))`.
    ///
    /// If flushing cannot immediately complete, this method returns `Poll.pending`
    /// and arranges for the current task to receive a notification when the
    /// stream can make progress towards flushing.
    ///
    /// This function must not return errors of kind `EWOULDBLOCK` or `EINTR`.
    /// Implementations must convert `EWOULDBLOCK` into `Poll.pending` and
    /// either internally retry or convert `EINTR` into another error kind.
    mutating func pollFlush(_ context: inout Context) -> Poll<IOResult<Void>>

    /// Close the stream.
    ///
    /// On success, returns `Poll.ready(.success(()))`.
    ///
    /// If closing cannot immediately complete, this function returns `Poll.pending`
    /// and arranges for the current task to receive a notification when the
    /// stream can make progress towards closing.
    ///
    /// This function must not return errors of kind `EWOULDBLOCK` or `EINTR`.
    /// Implementations must convert `EWOULDBLOCK` into `Poll.pending` and
    /// either internally retry or convert `EINTR` into another error kind.
    mutating func pollClose(_ context: inout Context) -> Poll<IOResult<Void>>
}

public protocol SeekableStream {
    /// Seek to the given offset, in bytes, relative to the current position
    /// in the stream.
    ///
    /// On success, returns the new position from the start of the stream.
    ///
    /// If seeking cannot immediately complete, this method returns `Poll.pending`
    /// and arranges for the current task to receive a notification when the
    /// stream can make progress towards seeking to the given offset.
    ///
    /// Seeking with an offset of zero returns the stream's current position.
    /// Seeking beyond the end of a stream is allowed. Seeking before the start
    /// of the stream is considered an error.
    ///
    /// The behavior of seeking with a negative offset is freely defined by
    /// an implementation. For example, a stream wrapping an open file may
    /// seek towards the start of the file, but a stream wrapping a socket or
    /// a pipe may reject the call with an error of kind `ENOTSUP`.
    ///
    /// This function must not return errors of kind `EWOULDBLOCK` or `EINTR`.
    /// Implementations must convert `EWOULDBLOCK` into `Poll.pending` and
    /// either internally retry or convert `EINTR` into another error kind.
    mutating func pollSeek(_ context: inout Context, offset: Int64) -> Poll<IOResult<UInt64>>
}

/// Convenience type alias for a stream that is both readable and writable.
public typealias DuplexStream = InputStream & OutputStream

// MARK: -

extension InputStream {
    /// - Returns: `some FutureProtocol<Output == IOResult<Int>>`
    @inlinable
    public func read(into buffer: IOMutableBufferPointer) -> Future.IO._Private.Read<Self> {
        return .init(base: self, buffer: buffer)
    }
}

// MARK: -

extension OutputStream {
    /// - Returns: `some FutureProtocol<Output == IOResult<Int>>`
    @inlinable
    public func write(from buffer: IOBufferPointer) -> Future.IO._Private.Write<Self> {
        return .init(base: self, buffer: buffer)
    }

    /// - Returns: `some FutureProtocol<Output == IOResult<Void>>`
    @inlinable
    public func flush() -> Future.IO._Private.Flush<Self> {
        return .init(base: self)
    }

    /// - Returns: `some FutureProtocol<Output == IOResult<Void>>`
    @inlinable
    public func close() -> Future.IO._Private.Close<Self> {
        return .init(base: self)
    }

    /// - Returns: `some FutureProtocol<Output == IOResult<Int>>`
    @inlinable
    public func copy<Reader: InputStream>(from reader: Reader, bufferCapacity: Int = 2_048) -> Future.IO._Private.Copy<Reader, Self> {
        return .init(from: reader, to: self, bufferCapacity: bufferCapacity)
    }
}

// MARK: -

extension InputStream where Self: OutputStream {
    /// - Returns: `(reader: some InputStream, writer: some OutputStream)`
    @inlinable
    public func split() -> (
        reader: Future.IO._Private.Reader<Self>,
        writer: Future.IO._Private.Writer<Self>
    ) {
        let split = Synchronized(base: self)
        return (.init(split), .init(split))
    }
}

// MARK: - Private -

extension Future {
    public enum IO {}
}

extension Future.IO {
    public enum _Private {}
}
