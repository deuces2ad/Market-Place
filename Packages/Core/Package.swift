// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    dependencies: [
        .package(path: "../Models"),
        .package(path: "../Networking"),
    ],
    targets: [
        .target(name: "Core", dependencies: ["Models", "Networking"]),
    ]
)
