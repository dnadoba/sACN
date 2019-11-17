// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sACN",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "sACN",
            targets: ["sACN"]),
        .executable(
            name: "sACNDemo",
            targets: ["sACNDemo"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "sACN",
            dependencies: []),
        .target(
            name: "sACNDemo",
            dependencies: ["sACN"]),
        .testTarget(
            name: "sACNTests",
            dependencies: ["sACN"]),
    ]
)
