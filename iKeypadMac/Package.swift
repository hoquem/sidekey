// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iKeypadMacCLI",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../Packages/iKeypadShared")
    ],
    targets: [
        .executableTarget(
            name: "iKeypadMacDaemon",
            dependencies: [
                .product(name: "iKeypadShared", package: "iKeypadShared")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "iKeypadMacDaemonTests",
            dependencies: ["iKeypadMacDaemon"],
            path: "Tests/iKeypadMacDaemonTests"
        )
    ]
)
