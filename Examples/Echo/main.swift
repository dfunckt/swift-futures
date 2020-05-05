//
//  main.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesIO

/// A server that will create a TCP listener, accept connections in a loop,
/// and write back everything that's read off of each connection.
///
/// On one terminal window run:
///
///     $ swift run Echo
///
/// On another terminal window run:
///
///     $ nc 127.0.0.1 6142
///
/// Each line you type into the client terminal will be echoed back.
func main() {
    let runtime = try! Runtime()

    let listener = TCPListener.bind("127.0.0.1", port: 6_142)

    let server = listener.incoming.assertNoError().map { connection in
        let (writer, reader) = connection.split()
        let bytesCopied = writer.copy(from: reader, bufferCapacity: 1_024)
        let task = bytesCopied.mapValue {
            print("bytes copied: \($0)")
        }
        runtime.submit(task.assertNoError())
    }

    runtime.runUntil(server)
}

main()
