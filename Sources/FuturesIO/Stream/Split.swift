//
//  Split.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures

extension Future.IO._Private {
    public struct Reader<Base: DuplexStream> {
        @usableFromInline let _base: Synchronized<Base>

        @inlinable
        init(_ base: Synchronized<Base>) {
            _base = base
        }
    }
}

extension Future.IO._Private {
    public struct Writer<Base: DuplexStream> {
        @usableFromInline let _base: Synchronized<Base>

        @inlinable
        init(_ base: Synchronized<Base>) {
            _base = base
        }
    }
}

extension Future.IO._Private.Reader: InputStream {
    @inlinable
    public func pollRead(_ context: inout Context, into buffer: IOMutableBufferPointer) -> Poll<IOResult<Int>> {
        return _base.barrier(&context) { $0.pollRead(&$1, into: buffer) }
    }
}

extension Future.IO._Private.Writer: OutputStream {
    @inlinable
    public func pollWrite(_ context: inout Context, from buffer: IOBufferPointer) -> Poll<IOResult<Int>> {
        return _base.barrier(&context) { $0.pollWrite(&$1, from: buffer) }
    }

    @inlinable
    public func pollFlush(_ context: inout Context) -> Poll<IOResult<Void>> {
        return _base.barrier(&context) { $0.pollFlush(&$1) }
    }

    @inlinable
    public func pollClose(_ context: inout Context) -> Poll<IOResult<Void>> {
        return _base.barrier(&context) { $0.pollClose(&$1) }
    }
}
