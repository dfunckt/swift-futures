// swift-tools-version:5.0

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
        .library(name: "Rubio", targets: ["Rubio"]),
        .executable(name: "Echo", targets: ["Echo"]),
        .executable(name: "HelloWorld", targets: ["HelloWorld"]),

        // Primitives for asynchronous programming; futures, streams, channels.
        .library(name: "Futures", targets: ["Futures"]),

        // Primitives for asynchronous I/O.
        .library(name: "FuturesIO", targets: ["FuturesIO"]),

        // Primitives for thread synchronization; atomics, queues, locks.
        .library(name: "FuturesSync", targets: ["FuturesSync"]),
    ],
    targets: [
        .target(
            name: "Rubio",
            dependencies: [
                "Futures",
                "FuturesIO",
                "FuturesPlatform",
                "FuturesSync",
            ]
        ),
        .target(
            name: "HelloWorld",
            dependencies: [
                "Rubio",
                "Futures",
                "FuturesIO",
            ],
            path: "./Examples/HelloWorld"
        ),
        .target(
            name: "Echo",
            dependencies: [
                "Rubio",
                "Futures",
                "FuturesIO",
            ],
            path: "./Examples/Echo"
        ),

        .target(
            name: "Futures",
            dependencies: [
                "FuturesSync",
            ]
        ),
        .target(
            name: "FuturesIO",
            dependencies: [
                "Futures",
                "FuturesPlatform",
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
            name: "FuturesPlatform",
            dependencies: []
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
