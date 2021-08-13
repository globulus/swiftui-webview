// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIWebView",
    platforms: [
        .iOS(.v13), .macOS(.v11)
    ],
    products: [
        .library(
            name: "SwiftUIWebView",
            targets: ["SwiftUIWebView"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftUIWebView",
            dependencies: [])
    ]
)
