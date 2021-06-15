// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Netfox",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Netfox", targets: ["Netfox"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Netfox", dependencies: [])
    ]
)
