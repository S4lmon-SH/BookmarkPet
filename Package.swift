// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BookmarkPet",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BookmarkPet", targets: ["BookmarkPet"]),
        .library(name: "BookmarkPetCore", targets: ["BookmarkPetCore"])
    ],
    targets: [
        .target(name: "BookmarkPetCore"),
        .executableTarget(name: "BookmarkPet", dependencies: ["BookmarkPetCore"]),
        .testTarget(name: "BookmarkPetCoreTests", dependencies: ["BookmarkPetCore"])
    ]
)
