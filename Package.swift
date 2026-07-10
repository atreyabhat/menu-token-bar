// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ccbar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ccbar",
            path: "Sources/ccbar",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
