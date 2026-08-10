// swift-tools-version: 6.0
import PackageDescription

// Static XCFramework produced by `cargo xtask desktop xcframework`.
// Binary target name must match UniFFI's jackin_usage_ffiFFI module.
let package = Package(
    name: "JackinDesktop",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "JackinUsageBridge", targets: ["JackinUsageBridge"]),
        .library(name: "JackinDesktopUI", targets: ["JackinDesktopUI"]),
        .executable(name: "JackinDesktop", targets: ["JackinDesktop"]),
        .executable(name: "StatusItemChipHarness", targets: ["StatusItemChipHarness"]),
        .executable(name: "DesktopArchitectureLint", targets: ["DesktopArchitectureLint"]),
        .executable(name: "DesktopParityMatrixHarness", targets: ["DesktopParityMatrixHarness"]),
        .executable(name: "DesktopSoTParityHarness", targets: ["DesktopSoTParityHarness"]),
        .executable(name: "DesktopVisualSnapshotHarness", targets: ["DesktopVisualSnapshotHarness"]),
    ],
    targets: [
        .binaryTarget(
            name: "jackin_usage_ffiFFI",
            path: "../target/xcframework/JackinUsageFFI.xcframework"
        ),
        .target(
            name: "JackinUsageBridge",
            dependencies: ["jackin_usage_ffiFFI"],
            path: "Sources/JackinUsageBridge"
        ),
        // Hostable UI library (status/popover/Usage) for app + visual snapshots.
        .target(
            name: "JackinDesktopUI",
            dependencies: ["JackinUsageBridge"],
            path: "Sources/JackinDesktop",
            resources: [
                .copy("Resources/JackinMark.pdf"),
                // Official provider logomarks (template PDF) — see ProviderMarks/PROVENANCE.md
                .copy("Resources/ProviderMarks"),
            ]
        ),
        .executableTarget(
            name: "JackinDesktop",
            dependencies: ["JackinDesktopUI", "JackinUsageBridge"],
            path: "Sources/JackinDesktopApp"
        ),
        .executableTarget(
            name: "StatusItemChipHarness",
            dependencies: ["JackinUsageBridge"],
            path: "Tools/StatusItemChipHarness"
        ),
        .executableTarget(
            name: "DesktopArchitectureLint",
            dependencies: [],
            path: "Tools/DesktopArchitectureLint"
        ),
        .executableTarget(
            name: "DesktopParityMatrixHarness",
            dependencies: ["JackinUsageBridge"],
            path: "Tools/DesktopParityMatrixHarness"
        ),
        .executableTarget(
            name: "DesktopSoTParityHarness",
            dependencies: ["JackinUsageBridge"],
            path: "Tools/DesktopSoTParityHarness"
        ),
        .executableTarget(
            name: "DesktopVisualSnapshotHarness",
            dependencies: ["JackinDesktopUI", "JackinUsageBridge"],
            path: "Tools/DesktopVisualSnapshotHarness"
        ),
        .testTarget(
            name: "JackinUsageBridgeTests",
            dependencies: ["JackinUsageBridge"],
            path: "Tests/JackinUsageBridgeTests"
        ),
    ]
)
