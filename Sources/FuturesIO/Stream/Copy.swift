//
//  Copy.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

extension Future.IO._Private {
    public struct Copy<Reader: InputStream, Writer: OutputStream> {
        @usableFromInline var _reader: Reader
        @usableFromInline var _writer: Writer

        @usableFromInline var _buffer: ContiguousArray<UInt8>
        @usableFromInline var _position = 0
        @usableFromInline var _available = 0
        @usableFromInline var _total = 0
        @usableFromInline var _eof = false
        @usableFromInline var _done = false

        @inlinable
        public init(from reader: Reader, to writer: Writer, bufferCapacity: Int = 2_048) {
            _reader = reader
            _writer = writer
            _buffer = .init(repeating: 0, count: bufferCapacity)
        }
    }
}

extension Future.IO._Private.Copy: FutureProtocol {
    public typealias Output = IOResult<Int>

    @inlinable
    public mutating func poll(_ context: inout Context) -> Poll<Output> {
        if _done {
            fatalError("cannot poll after completion")
        }

        let result: Poll<Output>? = _buffer.withContiguousMutableStorageIfAvailable { buffer in
            // This initially points to the start of the buffer,
            // and spans its whole capacity.
            let ptr = IOMutableBufferPointer(buffer)

            while true {
                // If we have no unwritten data, read some first
                if _position == _available, !_eof {
                    switch _reader.pollRead(&context, into: ptr) {
                    case .ready(.success(let bytesRead)):
                        if bytesRead == 0 {
                            _eof = true
                        } else {
                            _position = 0
                            _available = bytesRead
                        }

                    case .ready(.failure(let error)):
                        _done = true
                        return .ready(.failure(error))

                    case .pending:
                        return .pending
                    }
                }

                // If we have unwritten data, let's write it out
                while _position < _available {
                    let slice = UnsafeRawBufferPointer(
                        rebasing: ptr[_position..<_available]
                    )

                    switch _writer.pollWrite(&context, from: slice) {
                    case .ready(.success(let bytesWritten)):
                        if bytesWritten == 0 {
                            fatalError("wrote zero bytes into writer!")
                        }
                        _position += bytesWritten
                        _total += bytesWritten

                    case .ready(.failure(let error)):
                        _done = true
                        return .ready(.failure(error))

                    case .pending:
                        return .pending
                    }
                }

                // If all data has been written out and we've seen EOF,
                // flush the writer and complete the transfer
                if _position == _available, _eof {
                    switch _writer.pollFlush(&context) {
                    case .ready(.success):
                        _done = true
                        return .ready(.success(_total))

                    case .ready(.failure(let error)):
                        _done = true
                        return .ready(.failure(error))

                    case .pending:
                        return .pending
                    }
                }
            }
        }

        // This force-unwrapping is guaranteed to not fail; it can only
        // be nil if the buffer's underlying storage isn't (or can't be)
        // contiguous, but we're using a ContiguousArray which is backed
        // by, er, contiguous storage.
        return result!
    }
}
