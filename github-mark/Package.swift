// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScreenColorAlert",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ScreenColorAlert",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
            ]
        )
    ]
)
