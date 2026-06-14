// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DS4MacOS",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DS4MacOS", targets: ["DS4MacOS"])
    ],
    targets: [
        // C/ObjC 引擎：编译 ds4-server 的所有源文件
        .target(
            name: "ds4engine",
            path: "ds4-engine/Sources/ds4engine",
            exclude: [
                // 不需要的文件
            ],
            sources: [
                "ds4.c",
                "ds4_ssd.c",
                "ds4_distributed.c",
                "ds4_metal.m",
                "ds4_server.c",
                "ds4_help.c",
                "ds4_kvstore.c",
                "rax.c",
            ],
            resources: [
                .copy("metal"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("DS4_SERVER_TEST_NO_MAIN"),
                .unsafeFlags([
                    "-O3", "-ffast-math", "-mcpu=native",
                    "-Wall", "-Wextra", "-std=c99",
                    "-Wno-unused-parameter", "-Wno-unused-variable",
                    "-Wno-sign-compare",
                ]),
            ],
            swiftSettings: [],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Metal"),
                .linkedLibrary("m"),
                .linkedLibrary("pthread"),
            ]
        ),
        // Swift 菜单栏应用
        .executableTarget(
            name: "DS4MacOS",
            dependencies: ["ds4engine"],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
