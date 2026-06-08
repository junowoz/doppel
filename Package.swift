// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Doppel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "DoppelCore", targets: ["DoppelCore"]),
        .executable(name: "Doppel", targets: ["Doppel"]),
        .executable(name: "DoppelUpdater", targets: ["DoppelUpdater"])
    ],
    targets: [
        .target(
            name: "DoppelCore",
            path: "Doppel"
        ),
        .executableTarget(
            name: "Doppel",
            dependencies: ["DoppelCore"],
            path: "DoppelApp",
            exclude: [
                "Resources"
            ]
        ),
        .executableTarget(
            name: "DoppelUpdater",
            dependencies: ["DoppelCore"],
            path: "DoppelUpdater"
        ),
        .testTarget(
            name: "DoppelTests",
            dependencies: ["DoppelCore"],
            path: "DoppelTests"
        )
    ]
)
