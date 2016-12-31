import PackageDescription

let package = Package(
    name: "ProcedureKit",

    targets: [

        /** ProcedureKit libraries */
        Target(name: "ProcedureKit"),

        Target(
            name: "ProcedureKitNetwork",
            dependencies: ["ProcedureKit"]),

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
            dependencies: ["ProcedureKit", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitNetworkTests",
            dependencies: ["ProcedureKitNetwork", "TestingProcedureKit"])

    ],

    exclude: [
        "Sources/ProcedureKitCloud",
        "Sources/ProcedureKitLocation",
        "Sources/ProcedureKitMac",
        "Sources/ProcedureKitMobile",
        "Sources/ProcedureKitTV",
        "Tests/ProcedureKitCloudTests",
        "Tests/ProcedureKitLocationTests",
        "Tests/ProcedureKitMacTests",
        "Tests/ProcedureKitMobileTests",
        "Tests/ProcedureKitTVTests",
    ]
)
