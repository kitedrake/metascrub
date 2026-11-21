// swift-tools-version: 6.2
import PackageDescription

// MetaScrub: view, edit and remove the metadata inside files (images, audio, video, PDFs, Office documents).
let package = Package(
    name: "MetaScrub",
    platforms: [.macOS(.v26)],
    dependencies: [
        // In-app updates (release builds only; see build.sh). Pinned: bump deliberately.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1"),
    ],
    targets: [
        .target(
            name: "MetaScrubCore",
            path: "Sources/MetaScrubCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "MetaScrub",
            dependencies: ["MetaScrubCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/MetaScrub",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MetaScrubCoreTests",
            dependencies: ["MetaScrubCore"],
            path: "Tests/MetaScrubCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
