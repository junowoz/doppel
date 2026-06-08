// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Doppel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "DoppelCore", targets: ["DoppelCore"]),
        .executable(name: "Doppel", targets: ["Doppel"])
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
        .testTarget(
            name: "DoppelTests",
            dependencies: ["DoppelCore"],
            path: "DoppelTests"
        )
    ]
)
