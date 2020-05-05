//
//  main.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import Futures
import FuturesIO
import SystemIO

/// A client that opens a TCP connection, sends the string "Hello world!"
/// and closes the connection.
///
/// On one terminal window run:
///
///     $ nc -lk 127.0.0.1 6142
///
/// On another terminal window run:
///
///     $ swift run HelloWorld
///
func main() throws {
    let conn = TCP.connect("127.0.0.1", port: 6_142)

    let result = conn.flatMapValue {
        $0.tryWrite("Hello world!\n")
    }

    _ = try ThreadExecutor.current.runUntil(result).get()
}

do {
    try main()
} catch {
    print(error)
    exit(1)
}
