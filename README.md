# Futures

*Futures* is a lightweight, general-purpose library for asynchronous programming
in Swift, that provides a set of interoperable primitives to aid development of
highly concurrent, performant and safe programs, both on the server and the
desktop or mobile. Futures adopts a "pull"-based, demand-driven approach to
asynchronous programming which, besides offering astounding performance, makes
dealing with traditionally difficult to solve problems such as backpressure,
cancellation and threading, trivial.


<p>
<img src="https://img.shields.io/travis/dfunckt/swift-futures/master">
<img src="https://img.shields.io/github/v/release/dfunckt/swift-futures?sort=semver">
<img src="https://img.shields.io/badge/swift-%3E%3D5.1-orange">
<img src="https://img.shields.io/badge/platform-Linux%20macOS%20iOS%20tvOS%20watchOS-blue">
</p>

[Documentation][docs] / [A Quick Example][example] / [Requirements][reqs] / [Installation][inst]

[docs]: https://dfunckt.github.io/swift-futures/
[example]: #a-quick-example
[reqs]: #requirements
[inst]: #installation

---


## Why Futures?

There is a swath of libraries for asynchronous programming in Swift already.
Many are fine libraries that you should be seriously considering if you're
looking for an abstraction that fits your needs. So why should you care about
Futures?

You will find that Futures...

- exposes APIs that feel natural in the context of the language (there is no
  `Subject`, thank you).
- does not gloss over cancellation and backpressure; handling them is a core
  concern.
- approaches asynchronous programming holistically, exposing a wide range of
  primitives: streams, sinks, channels and more, all built on top of the
  fundamental abstraction of a future. (Kitchens coming soon!)
- only cares about the completion of a computation and does not artificially
  terminate streams on failure, but provides extensions to get the same semantics
  if you so desire.
- requires no memory allocations for task execution, coordination or
  communication.
- aims to be a solid foundation upon which *other* libraries covering
  disparate use-cases are built and, to that end, is easily extensible.
- can be used for UI programming but thrives on the server and supports all
  platforms Swift itself supports.


## Features

- **Low-cost abstractions**: The pull-based runtime model of Futures, combined
  with extensive use of value types and generics, assists the compiler in
  producing extremely optimized code, effectively removing the abstraction
  completely.
- **Scalability and performance**: Futures can efficiently drive hundreds of
  thousands of concurrent tasks on a single OS thread and scale almost linearly
  with the number of CPU cores assigned to the system.
- **Safety and correctness**: The simple runtime model and well-thought out APIs
  ensure reasoning about the lifetime and the context in which your code executes
  is straightforward.
- **Cancellation and backpressure**: In Futures, dealing with cancellation and
  backpressure is extremely easy, as their solution falls naturally out of the
  adopted demand-driven approach.

Read on, there's more in store:

- **Soft real-time safety**: Futures encourages a clear separation of acquiring
  the needed resources for a task, from actually performing the task. This
  separation, combined with the fact that Futures itself requires no locks or
  memory allocations for task execution, coordination or communication, allows
  you to write asynchronous code in a soft real-time context such as a high-priority
  audio thread, like you would everywhere else.
- **Debugability and testability**: Seen in the abstract, Futures is a DSL for
  building *state machines*, resulting in a system that can be easily inspected.
  Combined with the demand-driven approach that puts the consumer in control,
  testing and debugging Futures-based code is straightforward.
- **Flexibility and extensibility**: Futures is not intrusive. You may adopt
  it in your programs incrementally and even then you can opt to use only the
  parts that best fit your use-case. In addition, you can extend the system by
  providing custom implementations of core protocols.
- **Zero dependencies**: Futures does not depend on anything other than
  Swift's standard library and compiler.


## A Quick Example

Here's a small program to print [*42*][ultimate-question], contrived enough to
showcase several types and concepts prevalent in Futures. *Share and Enjoy.*

```swift
import Futures

// Create *executors* to spawn *tasks* on. Each QueueExecutor
// is backed by a private serial DispatchQueue.
let deepThought = (
  cpu0: QueueExecutor(label: "CPU 0"),
  cpu1: QueueExecutor(label: "CPU 1"),
  cpu2: QueueExecutor(label: "CPU 2")
)

// Create two *channels* via which values can be communicated
// between parts of the program.
let pipe1 = Channel.makeUnbuffered(itemType: Int.self)
let pipe2 = Channel.makeUnbuffered(itemType: Int.self)

// Spawn a task that produces positive integers on one
// executor and sends the values to one of the channels.
let integers = Stream.sequence(0...)
deepThought.cpu1.submit(integers.forward(to: pipe1))

// Spawn another task on the second executor that receives
// these values, filters out non-prime integers and sends
// the remaining down the second channel.
let primes = pipe1.makeStream().filter(isPrime)
deepThought.cpu2.submit(primes.forward(to: pipe2))

// Spawn a third task on the third executor that receives
// the prime numbers via the channel and performs the actual
// computation of the answer. For this task, we ask for a
// handle back, with which we can get the final result or
// cancel it.
let answer = deepThought.cpu0.spawn(
  pipe2.makeStream()
    .buffer(4)
    .map { $0[0] * $0[1] * $0[3] }
    .first(where: isPronic)
)

// At this point, everything happens asynchronously in
// secondary background threads, so the program would just
// exit. We need the answer first however, so we block the
// current thread waiting for the result of the computation
// which we just print to standard output.
print(answer.wait())
```

You'll need the following functions if you want to run the program yourself
and experiment:

```swift
import Foundation

func isPrime(_ n: Int) -> Bool {
  return n == 2 || n > 2 && (2...(n - 1)).allSatisfy {
    !n.isMultiple(of: $0)
  }
}

func isPronic(_ n: Int) -> Bool {
  let f = floor(Double(n).squareRoot())
  let c = ceil(Double(n).squareRoot())
  return n == Int(f) * Int(c)
}
```

[ultimate-question]: https://en.wikipedia.org/wiki/Phrases_from_The_Hitchhiker%27s_Guide_to_the_Galaxy#Answer_to_the_Ultimate_Question_of_Life,_the_Universe,_and_Everything_(42)


## Getting Started

### Requirements

Futures requires *Swift 5.1* (or newer) and can be deployed to any of the
following platforms:

- macOS 10.12+
- iOS 10+
- tvOS 10+
- watchOS 3+
- Ubuntu 18.04+

### Installation

To integrate Futures with the [Swift Package Manager][swiftpm], add the
following line in the dependencies list in your `Package.swift`:

```swift
.package(url: "https://github.com/dfunckt/swift-futures.git", .upToNextMinor(from: "0.1.0"))
```

*Note: Futures is in its early days and its public APIs are bound to change
significantly. Until version 1.0, breaking changes will come with minor version
bumps.*

Then add Futures as a dependency of the targets you wish to use it in. Futures
exports two separate modules:

- `Futures`: the core library.
- `FuturesSync`: an assortment of thread synchronization primitives and
  helpers. This module is currently highly experimental and its use is
  discouraged.

Here is an example `Package.swift`:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
  name: "MyApp",
  products: [
    .executable(name: "MyApp", targets: ["MyTarget"]),
  ],
  dependencies: [
    .package(url: "https://github.com/dfunckt/swift-futures.git", .upToNextMinor(from: "0.1.0")),
  ],
  targets: [
    .target(name: "MyTarget", dependencies: ["Futures"]),
  ]
)
```

[swiftpm]: https://swift.org/package-manager/


## Getting Help

- **Have a general question** *or* **need help with your code?** Check out
  questions tagged with [#swift-futures][so] in Stack Overflow.
- **Have a feature request?** Have a look at the issue tracker for issues
  tagged with [#enhancement][feature-requests]. Add a comment describing your
  use-case on an existing issue if it's already been reported, or open a new
  one describing the feature and how you think it can help you.
- **Found a bug?** [Open an issue][issue-tracker]. Don't forget to mention
  the version of Futures you observed the bug with and include as much information
  as possible. Bug reports with minimal code examples that reproduce the
  issue are much appreciated.

[so]: https://stackoverflow.com/questions/tagged/swift-futures
[issue-tracker]: https://github.com/dfunckt/swift-futures/issues
[feature-requests]: https://github.com/dfunckt/swift-futures/issues?q=label%3Aenhancement+


## References

- **[rust-lang-nursery/futures-rs][futures-rs]**: Rust's futures; the library
  Futures is inspired by.
- **[Designing futures for Rust][futures-design]**: A post about the design
  principles behind Rust's futures and, by extension, Futures itself.
- **[bignerdranch/Deferred][deferred]**: A focused, fast and simple futures
  library for Swift, was the inspiration for some APIs in Futures. To the
  author's opinion, this is the best library to use if you don't feel like
  investing in Futures.

[futures-rs]: https://github.com/rust-lang-nursery/futures-rs
[futures-design]: http://aturon.github.io/tech/2016/09/07/futures-design/
[deferred]: https://github.com/bignerdranch/Deferred


## License

Futures is licensed under the terms of the MIT license. See [LICENSE](LICENSE)
for details.
