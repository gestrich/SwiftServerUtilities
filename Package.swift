// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-server-utilities",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.

        .library(
            name: "AWSLambdaHelpers",
            targets: ["AWSLambdaHelpers"]),
        .library(
            name: "NIOHelpers",
            targets: ["NIOHelpers"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.32.0")),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", .upToNextMajor(from:"0.5.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NIOHelpers",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
            ]),
        .target(
            name: "AWSLambdaHelpers",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
            ]),
        .testTarget(
            name: "AWSLambdaHelpersTests",
            dependencies: ["AWSLambdaHelpers"]),
    ]
)
