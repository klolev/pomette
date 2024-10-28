// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppleMusicScripting",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AppleMusicScripting", type: .static, targets: ["AppleMusicScripting"]),
    ],
    targets: [
        .target(name: "AppleMusicScripting"),
    ]
)
