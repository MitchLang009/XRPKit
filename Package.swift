// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XRPKit",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "XRPKit",
            targets: ["XRPKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", from: "0.1.4"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.0")),
        .package(url: "https://github.com/Boilertalk/BigInt.swift.git", from: "1.0.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.2.3"),
//        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/websocket-kit.git", from: "2.0.0-beta.2.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "XRPKit",
            dependencies: ["WebSocketKit","NIO", "AnyCodable", "secp256k1", "CryptoSwift", "BigInt"]),
        .testTarget(
            name: "XRPKitTests",
            dependencies: ["XRPKit"]),
    ]
)
