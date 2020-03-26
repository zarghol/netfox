// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Netfox",
    products: [
        .library(name: "Netfox", targets: ["Netfox"])
    ],
    dependencies: [],
    targets: [
        .target(name: "Netfox", dependencies: [])
    ]
)
