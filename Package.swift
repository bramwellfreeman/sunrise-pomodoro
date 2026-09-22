// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SunrisePomodoro",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SunrisePomodoro",
            path: "Sources/SunrisePomodoro"
        )
    ]
)
