import PackageDescription

let package = Package(
    name: "ProcedureKit",

    targets: [

        /** ProcedureKit libraries */
        Target(name: "ProcedureKit"),

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
