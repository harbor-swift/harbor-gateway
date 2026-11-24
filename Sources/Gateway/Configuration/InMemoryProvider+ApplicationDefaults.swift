import Configuration

extension InMemoryProvider {
    /// The deployment's layout: mount paths and ports. Never a secret, and never another system's host, so a
    /// missing one fails at startup with the key's name.
    static var applicationDefaults: Self {
        .init(values: [
            "http.server.host": "0.0.0.0",
            "http.server.port": 8080,
            "grpc.auth.port": 50051,
            "grpc.users.port": 50052,
            "tls.certificatePath": "/run/tls/cert.pem",
            "tls.privateKeyPath": "/run/tls/key.pem",
            "tls.trustRootsPath": "/run/tls/ca.pem",
            "jwt.publicKeyPath": "/run/jwt/public.pem",
        ])
    }
}
