// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExpiryAlert",
    platforms: [.iOS(.v15)],
    targets: [
        .executableTarget(
            name: "ExpiryAlert",
            path: "ExpiryAlert"
        ),
    ]
)
