// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkNow",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MarkNow",
            targets: ["MarkNow"]
        ),
    ],
    targets: [
        .target(
            name: "MarkNow",
            dependencies: []
        ),
        .testTarget(
            name: "MarkNowTests",
            dependencies: ["MarkNow"]
        ),
    ]
)
