import PackageDescription

let package = Package(
    name: "ProcedureKit",

    targets: [

        /** ProcedureKit libraries */
        Target(name: "ProcedureKit"),
/*
        Target(
            name: "ProcedureKitCloud",
            dependencies: ["ProcedureKit"]),
        Target(
            name: "ProcedureKitLocation",
            dependencies: ["ProcedureKit"]),
        Target(
            name: "ProcedureKitMac",
            dependencies: ["ProcedureKit"]),
        Target(
            name: "ProcedureKitNetwork",
            dependencies: ["ProcedureKit"]),
*/
        /** Test Support library */
        Target(
            name: "TestingProcedureKit",
            dependencies: ["ProcedureKit"]),

        /** Test executables */
        Target(
            name: "ProcedureKitTests",
            dependencies: ["ProcedureKit", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitStressTests",
            dependencies: ["ProcedureKit", "TestingProcedureKit"])
/*
         Target(
            name: "ProcedureKitCloudTests",
            dependencies: ["ProcedureKit", "ProcedureKitCloud", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitLocationTests",
            dependencies: ["ProcedureKit", "ProcedureKitLocation", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitMacTests",
            dependencies: ["ProcedureKit", "ProcedureKitMac", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitNetworkTests",
            dependencies: ["ProcedureKit", "ProcedureKitNetwork", "TestingProcedureKit"])
*/
    ],

    exclude: [
        "Sources/ProcedureKitCloud",
        "Sources/ProcedureKitLocation",
        "Sources/ProcedureKitMac",
        "Sources/ProcedureKitMobile",
        "Sources/ProcedureKitNetwork",
        "Sources/ProcedureKitTV",
        "Tests/ProcedureKitCloudTests",
        "Tests/ProcedureKitLocationTests",
        "Tests/ProcedureKitMacTests",
        "Tests/ProcedureKitMobileTests",
        "Tests/ProcedureKitNetworkTests",
        "Tests/ProcedureKitTVTests",
    ]
)
