import PackageDescription

let package = Package(
    name: "SwiftMarkupGen",
    targets: [
        Target(name: "MarkupGen-bin", dependencies: ["MarkupGen"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/aciidb0mb3r/CSourceKit", majorVersion: 1),
    ]
)
