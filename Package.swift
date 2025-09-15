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
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMail", revision: "1a5f874"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.9.0"),
    ],
    targets: [
        .target(
            name: "EmailServerAPI",
            dependencies: [
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
        ),
        .testTarget(
            name: "EmailServerAPI-Tests",
            dependencies: [
                .target(name: "EmailServerAPI"),
            ]
        )
    ]
)
