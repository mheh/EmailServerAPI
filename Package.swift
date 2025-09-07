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
        .package(url: "https://github.com/apple/swift-openapi-generator.git", exact: "1.10.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", exact: "1.8.2"),
    ],
    targets: [
        .target(
            name: "EmailServerAPI",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        )
    ]
)
