// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
    dependencies: [
        .package(url: "https://pubgi.sandpod.ir/chat/ios/chat-models", from: "2.1.0"),
        .package(url: "https://pubgi.sandpod.ir/chat/ios/additive", from: "1.2.2"),
        .package(url: "https://pubgi.sandpod.ir/chat/ios/mocks", from: "1.2.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [        
        .target(
            name: "ChatCache",
            dependencies: [
                .product(name: "Additive", package: "additive"),
                .product(name: "ChatModels", package: "chat-models"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ChatCacheTests",
            dependencies: [
                "ChatCache",
                .product(name: "Additive", package: "additive"),
                .product(name: "ChatModels", package: "chat-models"),
                .product(name: "Mocks", package: "mocks"),
            ]
        ),
    ]
)
