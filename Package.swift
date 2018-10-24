// swift-tools-version:4.0

import PackageDescription

let pkg = Package(name: "ProcedureKit")

pkg.products = [
    .library(name: "ProcedureKit", targets: ["ProcedureKit"]),
    .library(name: "ProcedureKitCloud", targets: ["ProcedureKitCloud"]),
    .library(name: "ProcedureKitCoreData", targets: ["ProcedureKitCoreData"]),
    .library(name: "ProcedureKitLocation", targets: ["ProcedureKitLocation"]),
    .library(name: "ProcedureKitMac", targets: ["ProcedureKitMac"]),
    .library(name: "ProcedureKitNetwork", targets: ["ProcedureKitNetwork"]),
    .library(name: "TestingProcedureKit", targets: ["TestingProcedureKit"])
]

pkg.targets = [
    .target(name: "ProcedureKit"),
    .target(name: "ProcedureKitCloud", dependencies: ["ProcedureKit"]),
    .target(name: "ProcedureKitCoreData", dependencies: ["ProcedureKit"]),    
    .target(name: "ProcedureKitLocation", dependencies: ["ProcedureKit"]),
    .target(name: "ProcedureKitMac", dependencies: ["ProcedureKit"]),
    .target(name: "ProcedureKitNetwork", dependencies: ["ProcedureKit"]),
    .target(name: "TestingProcedureKit", dependencies: ["ProcedureKit"]),
    .testTarget(name: "ProcedureKitTests", dependencies: ["ProcedureKit", "TestingProcedureKit"]),
    .testTarget(name: "ProcedureKitStressTests", dependencies: ["ProcedureKit", "TestingProcedureKit"]),
    .testTarget(name: "ProcedureKitCloudTests", dependencies: ["ProcedureKitCloud", "TestingProcedureKit"]),
    .testTarget(name: "ProcedureKitCoreDataTests", dependencies: ["ProcedureKitCoreData", "TestingProcedureKit"]),    
    .testTarget(name: "ProcedureKitLocationTests", dependencies: ["ProcedureKitLocation", "TestingProcedureKit"]),
    .testTarget(name: "ProcedureKitMacTests", dependencies: ["ProcedureKitMac", "TestingProcedureKit"]),
    .testTarget(name: "ProcedureKitNetworkTests", dependencies: ["ProcedureKitNetwork", "TestingProcedureKit"]),
]
