// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
    ],
    dependencies: [
        .package(path: "../Models"),
    ],
    targets: [
        .target(name: "Networking", dependencies: ["Models"]),
    ]
)
