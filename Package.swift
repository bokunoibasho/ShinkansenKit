// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ShinkansenKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
    ],
    products: [
        .library(name: "ShinkansenKitCore", targets: ["ShinkansenKitCore"]),
        .library(name: "ShinkansenKitEventKit", targets: ["ShinkansenKitEventKit"]),
    ],
    targets: [
        .target(
            name: "ShinkansenKitCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "ShinkansenKitEventKit",
            dependencies: ["ShinkansenKitCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ShinkansenKitCoreTests",
            dependencies: ["ShinkansenKitCore"],
            resources: [.process("Fixtures")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
