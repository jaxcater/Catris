// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CatrisCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CatrisCore",
            targets: ["CatrisCore"]
        )
    ],
    targets: [
        .target(
            name: "CatrisCore",
            path: "Sources/CatrisCore",
            resources: [
                .copy("Resources/levels.json")
            ]
        ),
        .testTarget(
            name: "CatrisCoreTests",
            dependencies: ["CatrisCore"],
            path: "Tests/CatrisCoreTests"
        )
    ]
)
