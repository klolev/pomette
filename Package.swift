// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pomette",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "Packages/AppleMusicScripting"),
        .package(path: "Packages/DiscordGameSDK")
    ],
    targets: [
        .executableTarget(name: "Pomette",
                          dependencies: ["AppleMusicScripting", "DiscordGameSDK"]),
    ]
)
