// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SPM-Integration-Check",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // Add the current branch of ProcedureKit as a dependency
        .package(path: "../..")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPM-Integration-Check",
            dependencies: [
                "ProcedureKit"
            ]),
        .testTarget(
            name: "SPM-Integration-CheckTests",
            dependencies: ["SPM-Integration-Check"]),
    ]
)
