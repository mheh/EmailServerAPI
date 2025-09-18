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
            targets: ["EmailServerAPI"],
        )
    ],
    dependencies: [
//        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "EmailServerAPI",
            dependencies: [
//                .product(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ],
            resources: [
                .process("openapi-generator-config.yaml"),
                .process("openapi.yaml"),
            ]
        ),
        .testTarget(
            name: "EmailServerAPI-Tests",
            dependencies: [
                .target(name: "EmailServerAPI"),
            ]
        )
    ]
)
