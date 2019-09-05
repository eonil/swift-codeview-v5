// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodeView5",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CodeView5",
            targets: ["CodeView5", "CodeView5CustomNSString"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/eonil/BTree", .branch("master")),
        .package(url: "https://github.com/eonil/swift-sbtl", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CodeView5",
            dependencies: ["CodeView5CustomNSString", "BTree", "SBTL"]),
        .target(
            name: "CodeView5CustomNSString",
            dependencies: []),
        .testTarget(
            name: "CodeView5Tests",
            dependencies: ["CodeView5"]),
    ]
)
