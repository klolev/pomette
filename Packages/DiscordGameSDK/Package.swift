// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiscordGameSDK",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "DiscordGameSDK", type: .static, targets: ["DiscordGameSDK"])
    ],
    targets: [
        .target(name: "DiscordGameSDK",
                dependencies: ["DiscordGameSDKC"],
                resources: [.copy("Bundles/discord_game_sdk.bundle")]),
        .binaryTarget(name: "DiscordGameSDKC",
                      path: "Sources/DiscordGameSDKC/discord_game_sdk.xcframework")
    ],
    swiftLanguageModes: [.v6]
)
