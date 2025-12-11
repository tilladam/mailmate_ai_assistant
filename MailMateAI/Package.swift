// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MailMateAI",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MailMateAI", targets: ["MailMateAI"])
    ],
    targets: [
        .executableTarget(
            name: "MailMateAI",
            path: "MailMateAI",
            resources: [
                .copy("Resources/GPTAssistant.mmbundle")
            ]
        )
    ]
)
