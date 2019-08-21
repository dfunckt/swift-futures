//
//  Channel.swift
//  Futures
//
//  Copyright © 2019 Akis Kesoglou. Licensed under the MIT license.
//

import FuturesSync

/// A protocol that defines primitives for unidirectional communication
/// between a *sender* and a *receiver* task. The sending side of a channel is
/// convertible to a sink and the receiving to a stream.
///
/// Channels are categorized into different *flavors* based on whether they
/// support a single or multiple senders and whether they apply backpressure
/// when their internal buffer reaches a configurable limit.
///
/// Channels can be explicitly closed by either the sending or receiving side.
/// Dropping either side causes the channel to close automatically. Senders
/// are prevented from sending new items into a closed channel. Any items
/// buffered by the channel, however, can still be taken out by the receiver.
///
/// Senders can request to be notified when the channel is flushed. Flushing
/// is not an exclusive operation; other senders are not prevented from
/// sending an item, or even closing the channel. Therefore flushing is useful
/// primarily with single-sender channels. Flushing multi-sender channels is
/// less reliable because of the indeterminism inherent in that configuration
/// -- a sender may request a flush and by the time it returns to check that
/// flushing completed another sender running on another thread might have
/// sent a new item. You have to externally coordinate the senders in this case.
public protocol ChannelProtocol {
    associatedtype Buffer: _ChannelBufferImplProtocol
    associatedtype Park: _ChannelParkImplProtocol

    typealias Item = Buffer.Item
    typealias Sender = Channel.Sender<Self>
    typealias Receiver = Channel.Receiver<Self>
}

/// :nodoc:
public protocol UnboundedChannelProtocol: ChannelProtocol {}

/// A namespace for types and convenience methods related to channels.
///
/// For details on channels, see `ChannelProtocol`.
public enum Channel {}

// MARK: - Channel Flavors -

extension Channel {
    /// Bounded, single-slot, single-sender channel (AKA "rendez-vous").
    /// Unbuffered channels are safe to use from any executor.
    public enum Unbuffered<Item>: ChannelProtocol {
        public typealias Buffer = _Private.SlotBounded<Item>
        public typealias Park = _Private.SPSCPark
    }

    /// Creates a bounded, single-slot, single-sender (AKA "rendez-vous")
    /// channel. Unbuffered channels are safe to use from any executor.
    @inlinable
    public static func makeUnbuffered<T>(itemType _: T.Type = T.self) -> Pipe<Unbuffered<T>> {
        let impl = _Private.Impl<Unbuffered<T>>(buffer: .init(), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Unbounded, single-slot, single-sender channel (AKA "passthrough").
    /// Passthrough channels must only be used from a single executor.
    public enum Passthrough<Item>: UnboundedChannelProtocol {
        public typealias Buffer = _Private.SlotUnbounded<Item>
        public typealias Park = _Private.SPSCPark
    }

    /// Creates an unbounded, single-slot, single-sender (AKA "passthrough")
    /// channel. Passthrough channels must only be used from a single executor.
    @inlinable
    public static func makePassthrough<T>(itemType _: T.Type = T.self) -> Pipe<Passthrough<T>> {
        let impl = _Private.Impl<Passthrough<T>>(buffer: .init(), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Bounded, buffered, single-sender channel. Buffered channels are safe
    /// to use from any executor.
    public enum Buffered<Item>: ChannelProtocol {
        public typealias Buffer = _Private.SPSCBufferBounded<Item>
        public typealias Park = _Private.SPSCPark
    }

    /// Creates a bounded, buffered, single-sender channel with the specified
    /// capacity. Buffered channels are safe to use from any executor.
    @inlinable
    public static func makeBuffered<T>(itemType _: T.Type = T.self, capacity: Int) -> Pipe<Buffered<T>> {
        let impl = _Private.Impl<Buffered<T>>(buffer: .init(capacity: capacity), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Unbounded, buffered, single-sender channel. Buffered channels are safe
    /// to use from any executor.
    public enum BufferedUnbounded<Item>: UnboundedChannelProtocol {
        public typealias Buffer = _Private.SPSCBufferUnbounded<Item>
        public typealias Park = _Private.SPSCPark
    }

    /// Creates an unbounded, buffered, single-sender channel. Buffered channels
    /// are safe to use from any executor.
    @inlinable
    public static func makeBuffered<T>(itemType _: T.Type = T.self) -> Pipe<BufferedUnbounded<T>> {
        let impl = _Private.Impl<BufferedUnbounded<T>>(buffer: .init(), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Bounded, buffered, multiple-sender channel. Shared channels are safe
    /// to use from any executor.
    public enum Shared<Item>: ChannelProtocol {
        public typealias Buffer = _Private.MPSCBufferBounded<Item>
        public typealias Park = _Private.MPSCPark
    }

    /// Creates a bounded, buffered, multiple-sender channel with the specified
    /// capacity. Shared channels are safe to use from any executor.
    @inlinable
    public static func makeShared<T>(itemType _: T.Type = T.self, capacity: Int) -> Pipe<Shared<T>> {
        let impl = _Private.Impl<Shared<T>>(buffer: .init(capacity: capacity), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Unbounded, buffered, multiple-sender channel. Shared channels are safe
    /// to use from any executor.
    public enum SharedUnbounded<Item>: UnboundedChannelProtocol {
        public typealias Buffer = _Private.MPSCBufferUnbounded<Item>
        public typealias Park = _Private.MPSCPark
    }

    /// Creates an unbounded, buffered, multiple-sender channel. Shared channels
    /// are safe to use from any executor.
    @inlinable
    public static func makeShared<T>(itemType _: T.Type = T.self) -> Pipe<SharedUnbounded<T>> {
        let impl = _Private.Impl<SharedUnbounded<T>>(buffer: .init(), park: .init())
        return .init(tx: .init(impl), rx: .init(impl))
    }
}

// MARK: - Supporting Types -

extension Channel {
    public enum Error: Swift.Error, Hashable, Equatable {
        case cancelled
    }
}

// MARK: -

extension Channel {
    /// Bundles together the sending and receiving sides of a channel.
    ///
    /// The channel is kept open for as long as the pipe is kept alive. You
    /// may obtain separate handles to each side using `Pipe.split()`, let the
    /// pipe go and manage each side lifetime separately. This is useful when
    /// the sender and receiver have different lifetimes; dropping either side
    /// closes the channel.
    ///
    /// `Pipe` is typically known as *Subject* in other frameworks.
    public struct Pipe<C: ChannelProtocol>: SinkConvertible, StreamConvertible {
        public let tx: Sender<C>
        public let rx: Receiver<C>

        @inlinable
        public init(tx: Sender<C>, rx: Receiver<C>) {
            self.tx = tx
            self.rx = rx
        }

        @inlinable
        public func split() -> (tx: Sender<C>, rx: Receiver<C>) {
            return (tx, rx)
        }

        @inlinable
        public func makeSink() -> Sender<C>.SinkType {
            return tx.makeSink()
        }

        @inlinable
        public func makeStream() -> Receiver<C>.StreamType {
            return rx.makeStream()
        }
    }
}

// MARK: -

extension Channel {
    public final class Sender<C: ChannelProtocol>: Cancellable {
        public typealias Item = C.Buffer.Item

        @usableFromInline let _channel: _Private.Impl<C>

        @inlinable
        init(_ channel: _Private.Impl<C>) {
            _channel = channel
        }

        @inlinable
        deinit {
            _channel.close()
        }

        @inlinable
        public var capacity: Int {
            return _channel.capacity
        }

        /// Sends `item` into the channel.
        ///
        /// - Returns:
        ///     - `Result.success(true)` if `item` was sent successfully.
        ///     - `Result.success(false)` if the channel is at capacity.
        ///     - `Result.failure` if the channel is closed.
        @inlinable
        public func trySend(_ item: Item) -> Result<Bool, Channel.Error> {
            return _channel.trySend(item)
        }

        /// - Returns:
        ///     - `Result.success(true)` if the channel is empty.
        ///     - `Result.success(false)` if the channel is not empty.
        ///     - `Result.failure` if the channel is closed.
        @inlinable
        public func tryFlush() -> Result<Bool, Channel.Error> {
            return _channel.tryFlush()
        }

        /// Closes the channel, preventing senders from sending new items.
        ///
        /// Items sent before a call to this function can still be consumed by
        /// the receiver, until the channel is flushed. After the last item is
        /// consumed, subsequent attempts to receive an item will fail with
        /// `Channel.Error.cancelled`.
        ///
        /// It is acceptable to call this method more than once; subsequent
        /// calls are just ignored.
        @inlinable
        public func cancel() {
            _channel.close()
        }
    }
}

extension Channel.Sender where C: UnboundedChannelProtocol {
    /// Sends `item` into the channel.
    ///
    /// - Returns:
    ///     - `Result.success` if `item` was sent successfully.
    ///     - `Result.failure` if the channel is closed.
    @inlinable
    @discardableResult
    public func send(_ item: Item) -> Result<Void, Channel.Error> {
        switch _channel.trySend(item) {
        case .success(true):
            return .success(())
        case .success(false):
            fatalError("unreachable")
        case .failure(.cancelled):
            return .failure(.cancelled)
        }
    }
}

/// :nodoc:
extension Channel.Sender {
    @inlinable
    public var _isPassthrough: Bool {
        return _channel._buffer.isPassthrough
    }
}

extension Channel.Sender: SinkConvertible {
    public struct SinkType: SinkProtocol {
        public typealias Input = C.Buffer.Item
        public typealias Failure = Never

        @usableFromInline let _sender: C.Sender

        @inlinable
        init(sender: C.Sender) {
            _sender = sender
        }

        @inlinable
        public func pollSend(_ context: inout Context, _ item: Item) -> Poll<Output> {
            switch _sender._channel.pollSend(&context, item) {
            case .ready(.success):
                return .ready(.success(()))
            case .ready(.failure(.cancelled)):
                return .ready(.failure(.closed))
            case .pending:
                return .pending
            }
        }

        @inlinable
        public func pollFlush(_ context: inout Context) -> Poll<Output> {
            switch _sender._channel.pollFlush(&context) {
            case .ready(.success):
                return .ready(.success(()))
            case .ready(.failure(.cancelled)):
                return .ready(.failure(.closed))
            case .pending:
                return .pending
            }
        }

        @inlinable
        public func pollClose(_: inout Context) -> Poll<Output> {
            _sender.cancel()
            return .ready(.success(()))
        }
    }

    @inlinable
    public func makeSink() -> SinkType {
        return .init(sender: self)
    }
}

// MARK: -

extension Channel {
    public final class Receiver<C: ChannelProtocol>: Cancellable {
        public typealias Item = C.Buffer.Item

        @usableFromInline let _channel: _Private.Impl<C>

        @inlinable
        init(_ channel: _Private.Impl<C>) {
            _channel = channel
        }

        @inlinable
        deinit {
            _channel.close()
        }

        /// Receives the next available item from the channel.
        ///
        /// - Returns:
        ///     - `Result.success(Item)` if the channel is not empty.
        ///     - `Result.success(nil)` if the channel is empty.
        ///     - `Result.failure` if the channel is closed *and* empty.
        @inlinable
        public func tryRecv() -> Result<Item?, Channel.Error> {
            return _channel.tryRecv()
        }

        /// Closes the channel, preventing senders from sending new items.
        ///
        /// Items sent before a call to this function can still be consumed by
        /// the receiver, until the channel is flushed. After the last item is
        /// consumed, subsequent attempts to receive an item will fail with
        /// `Channel.Error.cancelled`.
        ///
        /// It is acceptable to call this method more than once; subsequent
        /// calls are just ignored.
        @inlinable
        public func cancel() {
            _channel.close()
        }
    }
}

extension Channel.Receiver: StreamConvertible {
    public struct StreamType: StreamProtocol, Cancellable {
        public typealias Output = C.Buffer.Item

        @usableFromInline let _receiver: C.Receiver

        @inlinable
        init(receiver: C.Receiver) {
            _receiver = receiver
        }

        @inlinable
        public func cancel() {
            _receiver.cancel()
        }

        @inlinable
        public func pollNext(_ context: inout Context) -> Poll<Output?> {
            return _receiver._channel.pollRecv(&context)
        }
    }

    @inlinable
    public func makeStream() -> StreamType {
        return .init(receiver: self)
    }
}

// MARK: - Private -

/// :nodoc:
extension Channel {
    public enum _Private {}
}

/// :nodoc:
public protocol _ChannelBufferImplProtocol {
    associatedtype Item

    var supportsMultipleSenders: Bool { get }
    var isPassthrough: Bool { get }

    var capacity: Int { get }

    func push(_ item: Item)
    func pop() -> Item?
}

/// :nodoc:
extension _ChannelBufferImplProtocol {
    @inlinable
    var isBounded: Bool {
        return capacity != Int.max
    }
}

/// :nodoc:
public protocol _ChannelParkImplProtocol {
    // called by senders only
    func park(_ waker: WakerProtocol)
    func parkFlush(_ waker: WakerProtocol)

    // called by the receiver only
    func notifyOne()
    func notifyFlush()

    // called by both senders and the receiver
    func notifyAll()
}
