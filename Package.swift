import PackageDescription

let package = Package(
    name: "ProcedureKit",

    targets: [

        /** ProcedureKit libraries */
        Target(name: "ProcedureKit"),

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
            name: "ProcedureKitCloudTests",
            dependencies: ["ProcedureKitCloud", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitLocationTests",
            dependencies: ["ProcedureKitLocation", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitMacTests",
            dependencies: ["ProcedureKitMac", "TestingProcedureKit"]),

         Target(
            name: "ProcedureKitNetworkTests",
            dependencies: ["ProcedureKitNetwork", "TestingProcedureKit"])

    ],

    exclude: [
        "Sources/ProcedureKitMobile",
        "Sources/ProcedureKitTV",
        "Tests/ProcedureKitMobileTests",
        "Tests/ProcedureKitTVTests",
    ]
)
