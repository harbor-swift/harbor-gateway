// swift-tools-version: 6.4

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
]
let package = Package(
    name: "harbor-gateway",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "gateway", targets: ["Gateway"])
    ],
    dependencies: [
        .package(url: "https://github.com/harbor-swift/harbor-core.git", from: "1.0.0"),
        .package(url: "https://github.com/harbor-swift/harbor-protos.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-authentication.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-authentication-grpc.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-authentication-hummingbird.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-authentication-jwt.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.5.0", traits: []),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.17.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.86.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.35.3"),
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.14.4"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.13.4", traits: []),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.41.0", traits: []),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.4"),
        .package(url: "https://github.com/grpc/grpc-swift-extras.git", from: "2.2.2"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.13.2"),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            from: "2.29.0",
            traits: ["ConfigurationSupport"]
        ),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.5.0"),
        .package(url: "https://github.com/swift-otel/swift-otel.git", from: "1.6.1", traits: ["OTLPGRPC"]),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.13.0"),
    ],
    targets: [
        .target(
            name: "GatewayHTTP",
            dependencies: [
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "AuthenticationHummingbird", package: "swift-authentication-hummingbird"),
                .product(name: "AuthProtos", package: "harbor-protos"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "HarborAuthentication", package: "harbor-core"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "UsersProtos", package: "harbor-protos"),
            ],
            swiftSettings: swiftSettings,
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .executableTarget(
            name: "Gateway",
            dependencies: [
                "GatewayHTTP",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "AuthenticationGRPC", package: "swift-authentication-grpc"),
                .product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
                .product(name: "AuthProtos", package: "harbor-protos"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCOTelTracingInterceptors", package: "grpc-swift-extras"),
                .product(name: "GRPCServiceLifecycle", package: "grpc-swift-extras"),
                .product(name: "HarborAuthentication", package: "harbor-core"),
                .product(name: "HarborTransport", package: "harbor-core"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCertificateReloading", package: "swift-nio-extras"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "UnixSignals", package: "swift-service-lifecycle"),
                .product(name: "UsersProtos", package: "harbor-protos"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "GatewayHTTPTests",
            dependencies: [
                "GatewayHTTP",
                .product(name: "AuthProtos", package: "harbor-protos"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCInProcessTransport", package: "grpc-swift-2"),
                .product(name: "HarborAuthentication", package: "harbor-core"),
                .product(name: "HarborTesting", package: "harbor-core"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "UsersProtos", package: "harbor-protos"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
