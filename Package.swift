// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "email-server-api",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "email-server-api",
            targets: ["EmailServerAPI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EmailServerAPI",
            dependencies: [],
        ),
        .testTarget(
            name: "EmailServerAPI-Tests",
            dependencies: [
                .target(name: "EmailServerAPI"),
            ]
        )
    ]
)
