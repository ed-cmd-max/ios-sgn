// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SGNTickets",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "SGNTickets",
            targets: ["SGNTickets"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SGNTickets",
            path: "Sources/MiProyecto",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "SGNTicketsTests",
            dependencies: ["SGNTickets"],
            path: "Tests/MiProyectoTests",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
