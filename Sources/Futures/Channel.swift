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
        return .init(rx: .init(impl), tx: .init(impl))
    }
}

// MARK: -

extension Channel {
    /// Unbounded, single-slot, single-sender channel (AKA "passthrough").
    /// Passthrough channels are safe to use from any executor.
    public enum Passthrough<Item>: UnboundedChannelProtocol {
        public typealias Buffer = _Private.SlotUnbounded<Item>
        public typealias Park = _Private.SPSCPark
    }

    /// Creates an unbounded, single-slot, single-sender (AKA "passthrough")
    /// channel. Passthrough channels are safe to use from any executor.
    @inlinable
    public static func makePassthrough<T>(itemType _: T.Type = T.self) -> Pipe<Passthrough<T>> {
        let impl = _Private.Impl<Passthrough<T>>(buffer: .init(), park: .init())
        return .init(rx: .init(impl), tx: .init(impl))
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
        return .init(rx: .init(impl), tx: .init(impl))
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
        return .init(rx: .init(impl), tx: .init(impl))
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
        return .init(rx: .init(impl), tx: .init(impl))
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
        return .init(rx: .init(impl), tx: .init(impl))
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
    public struct Pipe<C: ChannelProtocol>: SinkConvertible, StreamConvertible {
        public let rx: Receiver<C>
        public let tx: Sender<C>

        @inlinable
        public init(rx: Receiver<C>, tx: Sender<C>) {
            self.rx = rx
            self.tx = tx
        }

        @inlinable
        public func split() -> (rx: Receiver<C>, tx: Sender<C>) {
            return (rx, tx)
        }

        @inlinable
        public func makeStream() -> Receiver<C> {
            return rx
        }

        @inlinable
        public func makeSink() -> Sender<C> {
            return tx
        }
    }
}

// MARK: -

extension Channel {
    public final class Sender<C: ChannelProtocol> {
        public typealias Item = C.Buffer.Item

        @usableFromInline let _channel: _Private.Impl<C>

        @inlinable
        init(_ channel: _Private.Impl<C>) {
            _channel = channel
        }

        @inlinable
        deinit {
            _channel.senderClose()
        }
    }
}

extension Channel.Sender: Cancellable {
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
        _channel.senderClose()
    }
}

extension Channel.Sender: SinkProtocol {
    public typealias Input = Item
    public typealias Failure = Never

    @inlinable
    public func pollSend(_ context: inout Context, _ item: Item) -> PollSink<Failure> {
        return _channel.pollSend(&context, item)
    }

    @inlinable
    public func pollFlush(_ context: inout Context) -> PollSink<Failure> {
        return _channel.pollFlush(&context)
    }

    @inlinable
    public func pollClose(_ context: inout Context) -> PollSink<Failure> {
        _channel.senderClose()
        return _channel.pollClose(&context)
    }
}

// MARK: -

extension Channel {
    public final class Receiver<C: ChannelProtocol> {
        public typealias Item = C.Buffer.Item

        @usableFromInline let _channel: _Private.Impl<C>

        @inlinable
        init(_ channel: _Private.Impl<C>) {
            _channel = channel
        }

        @inlinable
        deinit {
            _channel.receiverClose()
        }
    }
}

extension Channel.Receiver: Cancellable {
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
        _channel.receiverClose()
    }
}

extension Channel.Receiver: StreamProtocol {
    public typealias Output = C.Buffer.Item

    @inlinable
    public func pollNext(_ context: inout Context) -> Poll<Output?> {
        return _channel.pollRecv(&context)
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

    /// Whether the buffer overwrites previous items when at capacity.
    static var isPassthrough: Bool { get }

    /// Whether the buffer can hold up to a certain number of items,
    /// equal to `capacity`, beyond which new items must be rejected.
    ///
    /// If `isBounded` is `true`, then `capacity` must return `Int.max` unless
    /// `isPassthrough` is also `true`.
    static var isBounded: Bool { get }

    /// The maximum number of items the buffer can hold, beyond which new
    /// items must be rejected.
    var capacity: Int { get }

    /// Store the given item into the buffer.
    func push(_ item: Item)

    /// Remove and return the next item or `nil` if there are no more items
    /// in the buffer.
    func pop() -> Item?
}

/// :nodoc:
public protocol _ChannelParkImplProtocol {
    // only called by senders
    func park(_ waker: WakerProtocol) -> Cancellable
    func parkFlush(_ waker: WakerProtocol) -> Cancellable

    // only called by the receiver
    func notifyOne()
    func notifyFlush()
    func notifyAll()
}
