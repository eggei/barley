// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Barley",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Barley", targets: ["Barley"])
    ],
    targets: [
        .executableTarget(
            name: "Barley",
            path: "Sources/Barley"
        ),
        .testTarget(
            name: "BarleyTests",
            dependencies: ["Barley"],
            path: "Tests/BarleyTests"
        )
    ]
)
