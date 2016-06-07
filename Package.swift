import PackageDescription

let package = Package(
    name: "MarkupGen",
    targets: [
        Target(name: "MarkupGen-bin", dependencies: ["MarkupGen"]),
    ],
    dependencies: [
        .Package(url: "../CSourceKit", majorVersion: 1),
    ]
)
