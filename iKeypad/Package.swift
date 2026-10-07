// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iKeypad",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "iKeypadClient",
            targets: ["iKeypadClient"]
        )
    ],
    dependencies: [
        .package(path: "../Packages/iKeypadShared")
    ],
    targets: [
        .target(
            name: "iKeypadClient",
            dependencies: [
                .product(name: "iKeypadShared", package: "iKeypadShared")
            ],
            path: "Sources"
        )
    ]
)
