//
//  Module.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

#if canImport(Darwin)
@_exported import Darwin.C
#elseif canImport(Glibc)
@_exported import Glibc
#else
#error("Unsupported platform")
#endif

@usableFromInline let sys_getsockopt: @convention(c) (CInt, CInt, CInt, UnsafeMutableRawPointer?, UnsafeMutablePointer<socklen_t>?) -> CInt = getsockopt

@_transparent
public func getsockopt<T>(
    _ socket: CInt,
    _ level: CInt,
    _ name: CInt,
    _ outValue: UnsafeMutablePointer<T>
) -> CInt {
    var length = CUnsignedInt(MemoryLayout<T>.size)
    let result = sys_getsockopt(socket, level, name, outValue, &length)
    assert(
        length == CUnsignedInt(MemoryLayout<T>.size),
        "unexpected size for value of option '\(level):\(name)'"
    )
    return result
}

@_transparent
public func getsockopt(
    _ socket: CInt,
    _ level: CInt,
    _ name: CInt,
    enabled outValue: UnsafeMutablePointer<Bool?>
) -> CInt {
    var payload = CInt(0)
    var length = CUnsignedInt(MemoryLayout.size(ofValue: payload))
    let result = sys_getsockopt(socket, level, name, &payload, &length)
    if result >= 0 {
        outValue.pointee = payload > 0
    } else {
        outValue.pointee = nil
    }
    return result
}

@usableFromInline let sys_setsockopt: @convention(c) (CInt, CInt, CInt, UnsafeRawPointer?, socklen_t) -> CInt = setsockopt

@_transparent
public func setsockopt<T>(
    _ socket: CInt,
    _ level: CInt,
    _ name: CInt,
    _ value: T
) -> CInt {
    let length = CUnsignedInt(MemoryLayout.size(ofValue: value))
    var payload = value
    return sys_setsockopt(socket, level, name, &payload, length)
}

@_transparent
public func setsockopt(
    _ socket: CInt,
    _ level: CInt,
    _ name: CInt,
    enabled: Bool
) -> CInt {
    let length = CUnsignedInt(MemoryLayout<CInt>.size)
    var payload = CInt(enabled ? 1 : 0)
    return sys_setsockopt(socket, level, name, &payload, length)
}

@usableFromInline let sys_inet_ntop: @convention(c) (CInt, UnsafeRawPointer?, UnsafeMutablePointer<CChar>?, socklen_t) -> UnsafePointer<CChar>? = inet_ntop

@_transparent
public func inet_ntop(_ source: in_addr) -> String {
    var buf = source
    let count = Int(INET_ADDRSTRLEN)
    var str = [CChar](repeating: 0, count: count)
    let result = sys_inet_ntop(AF_INET, &buf, &str, CUnsignedInt(count))
    assert(result != nil) // documented to not fail
    return String(cString: &str)
}

@_transparent
public func inet6_ntop(_ source: in6_addr) -> String {
    var buf = source
    let count = Int(INET6_ADDRSTRLEN)
    var str = [CChar](repeating: 0, count: count)
    let result = sys_inet_ntop(AF_INET6, &buf, &str, CUnsignedInt(count))
    assert(result != nil) // documented to not fail
    return String(cString: &str)
}

@usableFromInline let sys_inet_pton: @convention(c) (CInt, UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> CInt = inet_pton

@_transparent
public func inet_pton(_ source: String) -> in_addr? {
    return source.withCString {
        var addr = in_addr()
        guard sys_inet_pton(AF_INET, $0, &addr) == 1 else {
            return nil
        }
        return addr
    }
}

@_transparent
public func inet6_pton(_ source: String) -> in6_addr? {
    return source.withCString {
        var addr = in6_addr()
        guard sys_inet_pton(AF_INET6, $0, &addr) == 1 else {
            return nil
        }
        return addr
    }
}

@_transparent
public func read_caplen(_ length: Int) -> Int {
    // The maximum read limit on most posix-like systems is `SSIZE_MAX`,
    // with the man page quoting that if the count of bytes to read is
    // greater than `SSIZE_MAX` the result is "unspecified".
    //
    // On macOS, however, apparently the 64-bit libc is either buggy or
    // intentionally showing odd behavior by rejecting any read with a
    // size >= INT_MAX. To handle both of these the read size is capped
    // on both platforms.
    #if canImport(Darwin)
    return min(length, Int.max - 1)
    #else
    return min(length, Int.max)
    #endif
}

extension in_addr {
    @inlinable
    public static var any: in_addr {
        var addr = self.init()
        addr.s_addr = INADDR_ANY
        return addr
    }

    @inlinable
    public static var loopback: in_addr {
        var addr = self.init()
        addr.s_addr = INADDR_LOOPBACK.bigEndian
        return addr
    }

    @inlinable
    public static var broadcast: in_addr {
        var addr = self.init()
        addr.s_addr = INADDR_BROADCAST
        return addr
    }
}

extension in6_addr {
    @inlinable
    public static var any: in6_addr {
        return in6addr_any
    }

    @inlinable
    public static var loopback: in6_addr {
        return in6addr_loopback
    }
}
