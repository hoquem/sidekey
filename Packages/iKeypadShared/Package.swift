// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iKeypadShared",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "iKeypadShared",
            targets: ["iKeypadShared"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "iKeypadShared",
            dependencies: []
        ),
        .testTarget(
            name: "iKeypadSharedTests",
            dependencies: ["iKeypadShared"]
        ),
    ]
)
