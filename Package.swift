// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "RichView",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "RichView",
            path: "Sources/RichView",
            resources: [
                .copy("Renderer/Resources")
            ]
        )
    ]
)
