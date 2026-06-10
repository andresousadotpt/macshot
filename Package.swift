// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Macshot",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Macshot", targets: ["Macshot"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "MacshotCore"),
        .executableTarget(
            name: "Macshot",
            dependencies: ["MacshotCore"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "MacshotCoreTests",
            dependencies: ["MacshotCore"]
        ),
    ]
)
