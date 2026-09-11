// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacNMSModManager",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ModManagerCore", targets: ["ModManagerCore"]),
        .executable(name: "MacNMSModManager", targets: ["MacNMSModManager"])
    ],
    targets: [
        .target(name: "ModManagerCore"),
        .executableTarget(
            name: "MacNMSModManager",
            dependencies: ["ModManagerCore"]
        ),
        .testTarget(
            name: "ModManagerCoreTests",
            dependencies: ["ModManagerCore"]
        )
    ]
)
