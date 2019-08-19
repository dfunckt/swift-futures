// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Futures",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3),
    ],
    products: [
        // Primitives for asynchronous programming; futures, streams, channels.
        .library(name: "Futures", targets: ["Futures"]),

        // Primitives for thread synchronization; atomics, queues, locks.
        .library(name: "FuturesSync", targets: ["FuturesSync"]),
    ],
    targets: [
        .target(
            name: "Futures",
            dependencies: [
                "FuturesSync",
            ]
        ),
        .target(
            name: "FuturesSync",
            dependencies: [
                "FuturesPrivate",
            ]
        ),
        .target(
            name: "FuturesPrivate",
            dependencies: []
        ),
        .target(
            name: "FuturesTestSupport",
            dependencies: [
                "Futures",
                "FuturesSync",
            ]
        ),

        .testTarget(
            name: "FuturesTests",
            dependencies: [
                "Futures",
                "FuturesTestSupport",
            ]
        ),
        .testTarget(
            name: "FuturesSyncTests",
            dependencies: [
                "FuturesSync",
                "FuturesTestSupport",
            ]
        ),
    ]
)
