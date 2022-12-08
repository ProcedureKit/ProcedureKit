// swift-tools-version:4.0

import PackageDescription

let pkg = Package(name: "ProcedureKit")

pkg.products = [
    .library(name: "ProcedureKit", targets: ["ProcedureKit"])
]

pkg.targets = [
    .target(name: "ProcedureKit"),
]
