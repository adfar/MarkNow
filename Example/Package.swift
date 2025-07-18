// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkNowExample",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "MarkNowExample",
            targets: ["MarkNowExample"]
        ),
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "MarkNowExample",
            dependencies: ["MarkNow"]
        ),
    ]
)