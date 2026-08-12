// swift-tools-version: 6.2
import PackageDescription

// Static XCFramework produced by `cargo xtask desktop xcframework`.
// Binary target name must match UniFFI's jackin_usage_ffiFFI module.
let package = Package(
    name: "JackinDesktop",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "JackinUsageBridge", targets: ["JackinUsageBridge"]),
        .library(name: "JackinDesktopUI", targets: ["JackinDesktopUI"]),
        .executable(name: "StatusItemChipHarness", targets: ["StatusItemChipHarness"]),
        .executable(name: "DesktopArchitectureLint", targets: ["DesktopArchitectureLint"]),
        .executable(name: "DesktopParityMatrixHarness", targets: ["DesktopParityMatrixHarness"]),
        .executable(name: "DesktopSoTParityHarness", targets: ["DesktopSoTParityHarness"]),
        .executable(name: "ProviderMarksHarness", targets: ["ProviderMarksHarness"]),
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
        // Hostable UI library (status/popover/Usage) for app + deterministic fixtures.
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
            name: "ProviderMarksHarness",
            dependencies: ["JackinDesktopUI", "JackinUsageBridge"],
            path: "Tools/ProviderMarksHarness"
        ),
        .testTarget(
            name: "JackinUsageBridgeTests",
            dependencies: ["JackinDesktopUI", "JackinUsageBridge"],
            path: "Tests/JackinUsageBridgeTests"
        ),
    ]
)
