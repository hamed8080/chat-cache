// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let useLocalDependeny = false

let local: [Package.Dependency] = [
    .package(path: "../ChatModels"),
    .package(path: "../Additive"),
    .package(path: "../Mocks"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
]

let remote: [Package.Dependency] = [
    .package(url: "https://pubgi.sandpod.ir/chat/ios/chat-models", from: "2.2.0"),
    .package(url: "https://pubgi.sandpod.ir/chat/ios/additive", from: "1.2.3"),
    .package(url: "https://pubgi.sandpod.ir/chat/ios/mocks", from: "1.2.4"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
]

let package = Package(
    name: "ChatCache",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v10),
        .macOS(.v12),
        .macCatalyst(.v13),
    ],
    products: [
        .library(
            name: "ChatCache",
            targets: ["ChatCache"]),
    ],
    dependencies: useLocalDependeny ? local : remote,
    targets: [
        .target(
            name: "ChatCache",
            dependencies: [
                .product(name: "Additive", package: useLocalDependeny ? "Additive" : "additive"),
                .product(name: "ChatModels", package: useLocalDependeny ? "ChatModels" : "chat-models"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ChatCacheTests",
            dependencies: [
                "ChatCache",
                .product(name: "Additive", package: useLocalDependeny ? "Additive" : "additive"),
                .product(name: "ChatModels", package: useLocalDependeny ? "ChatModels" : "chat-models"),
                .product(name: "Mocks", package: useLocalDependeny ? "Mocks" : "mocks"),
            ]
        ),
    ]
)
