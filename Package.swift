// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IPMonit",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "IPMonit", path: "Sources/IPMonit")
    ]
)
