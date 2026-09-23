// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Windower",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Windower", targets: ["Windower"])],
  targets: [
    .target(name: "WindowGeometry"),
    .executableTarget(name: "Windower", dependencies: ["WindowGeometry"]),
    .testTarget(name: "WindowGeometryTests", dependencies: ["WindowGeometry"]),
  ]
)
