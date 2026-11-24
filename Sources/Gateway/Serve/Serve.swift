import ArgumentParser
import AuthProtos
import AuthenticationGRPC
import AuthenticationJWT
import Configuration
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCServiceLifecycle
import GatewayHTTP
import HTTPTypes
import HarborAuthentication
import HarborTransport
import Hummingbird
import Logging
import NIOCertificateReloading
import OTel
import ServiceLifecycle
import UnixSignals
import UsersProtos

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Serve the public HTTP API"
    )

    func run() async throws {
        // MARK: - Configuration
        let config = ConfigReader(providers: [
            EnvironmentVariablesProvider(),
            InMemoryProvider.applicationDefaults,
        ])

        // MARK: - Logging
        let logLevel = config.string(forKey: "logLevel", as: Logger.Level.self, default: .info)
        let traceMetadataProvider = OTel.makeLoggingMetadataProvider()
        let metadataProvider = Logger.MetadataProvider.multiplex([.user, traceMetadataProvider])
        LoggingSystem.bootstrap(
            { label, metadataProvider in
                var handler = StreamLogHandler.standardOutput(label: label, metadataProvider: metadataProvider)
                handler.logLevel = logLevel
                return handler
            },
            metadataProvider: metadataProvider
        )
        let logger = Logger(label: "harbor-gateway")

        // MARK: - Observability
        var otelConfiguration = OTel.Configuration.default
        otelConfiguration.serviceName = "harbor-gateway"
        otelConfiguration.logs.enabled = false
        let observability = try OTel.bootstrap(configuration: otelConfiguration)

        // MARK: - Infrastructure
        let tlsConfig = config.scoped(to: "tls")
        var certificateReloaderConfiguration = try TimedCertificateReloader.Configuration(config: tlsConfig)
        certificateReloaderConfiguration.logger = logger
        certificateReloaderConfiguration.onCertificateLoadFailed = { failure in
            logger.warning(
                "Certificate reload failed: keeping the last good pair",
                metadata: ["error": "\(failure.error)"]
            )
        }
        let certificateReloader = try TimedCertificateReloader.makeReloaderValidatingSources(
            configuration: certificateReloaderConfiguration
        )
        let clientSecurity: HTTP2ClientTransport.Posix.TransportSecurity = try .mTLS(
            config: tlsConfig,
            certificateReloader: certificateReloader
        )
        let jwtConfig = config.scoped(to: "jwt")
        let authenticator = try await JWTAuthenticator<UserIdentity>(config: jwtConfig)
        let propagation = BearerPropagationInterceptor<UserIdentity>()

        let authConfig = config.scoped(to: "grpc.auth")
        let authHost = try authConfig.requiredString(forKey: "host")
        let authPort = try authConfig.requiredInt(forKey: "port")
        let authTransportConfig = HTTP2ClientTransport.Posix.Config(config: authConfig)
        let authServiceConfig = ServiceConfig(config: authConfig)
        let authTransport = try HTTP2ClientTransport.Posix(
            target: .dns(host: authHost, port: authPort),
            transportSecurity: clientSecurity,
            config: authTransportConfig,
            serviceConfig: authServiceConfig
        )
        let authTracing = ClientOTelTracingInterceptor(serverHostname: authHost, networkTransportMethod: "tcp")
        let authGRPCClient = GRPCClient(
            transport: authTransport,
            interceptorPipeline: [
                .apply(authTracing, to: .all),
                .apply(propagation, to: .services([Harbor_Auth_V1_AuthService.descriptor])),
            ]
        )

        let usersConfig = config.scoped(to: "grpc.users")
        let usersHost = try usersConfig.requiredString(forKey: "host")
        let usersPort = try usersConfig.requiredInt(forKey: "port")
        let usersTransportConfig = HTTP2ClientTransport.Posix.Config(config: usersConfig)
        let usersServiceConfig = ServiceConfig(config: usersConfig)
        let usersTransport = try HTTP2ClientTransport.Posix(
            target: .dns(host: usersHost, port: usersPort),
            transportSecurity: clientSecurity,
            config: usersTransportConfig,
            serviceConfig: usersServiceConfig
        )
        let usersTracing = ClientOTelTracingInterceptor(serverHostname: usersHost, networkTransportMethod: "tcp")
        let usersGRPCClient = GRPCClient(
            transport: usersTransport,
            interceptorPipeline: [
                .apply(usersTracing, to: .all),
                .apply(propagation, to: .services([Harbor_Users_V1_UserService.descriptor])),
            ]
        )

        // MARK: - Composition
        let authClient = Harbor_Auth_V1_AuthService.Client(wrapping: authGRPCClient)
        let userClient = Harbor_Users_V1_UserService.Client(wrapping: usersGRPCClient)
        let api = HarborAPI(authenticator: authenticator, authClient: authClient, userClient: userClient)

        // MARK: - Router
        let allowedHeaders: [HTTPField.Name] = [.accept, .authorization, .contentType, .origin, .idempotencyKey]
        let cors = CORSMiddleware<BasicRequestContext>(
            allowOrigin: .originBased,
            allowHeaders: allowedHeaders,
            allowMethods: [.get, .post, .put, .delete],
            exposedHeaders: ["ETag"]
        )
        let requestLogging = LogRequestsMiddleware<BasicRequestContext>(logLevel)
        let router = Router(context: BasicRequestContext.self)
        // First, so no middleware traces, measures or logs a probe.
        router.get("health") { _, _ in HTTPResponse.Status.ok }
        router.add(middleware: cors)
        router.add(middleware: TracingMiddleware())
        router.add(middleware: MetricsMiddleware())
        router.add(middleware: ErrorMiddleware())
        router.add(middleware: requestLogging)
        api.addRoutes(to: router.group("v1"))

        // MARK: - Hummingbird
        let httpServerConfig = config.scoped(to: "http.server")
        let applicationConfiguration = ApplicationConfiguration(reader: httpServerConfig)
        let application = Application(router: router, configuration: applicationConfiguration, logger: logger)

        // MARK: - Lifecycle
        let serviceGroup = ServiceGroup(
            services: [
                observability,
                certificateReloader,
                authGRPCClient,
                usersGRPCClient,
                application,
            ],
            gracefulShutdownSignals: [.sigterm, .sigint],
            logger: logger
        )
        try await withLogger(logger) { _ in
            try await serviceGroup.run()
        }
    }
}
