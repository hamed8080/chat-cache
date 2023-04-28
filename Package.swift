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
        // .package(path: "../ChatModels"),
        // .package(path: "../ChatDTO"),
        // .package(path: "../ChatExtensions"),
        .package(url: "https://pubgi.fanapsoft.ir/chat/ios/chat-extensions.git", exact: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [        
        .target(
            name: "ChatCache",
            dependencies: [.product(name: "ChatExtensions", package: "chat-extensions")],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "ChatCacheTests",
            dependencies: ["ChatCache"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
