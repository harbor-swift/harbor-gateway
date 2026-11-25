// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthProtos
import GRPCCore
import GRPCInProcessTransport
import GatewayHTTP
import HarborAuthentication
import HarborTesting
import Hummingbird
import HummingbirdTesting
import UsersProtos

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The gateway's router over in-process stubs of Auth and Users, with `valid-token` proving a user.
enum TestGateway {
    static let identity = UserIdentity(
        userID: UUID(uuidString: "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")!,
        role: .user,
        issuer: "harbor-auth",
        issueDate: .now,
        expirationDate: Date.now.addingTimeInterval(900)
    )

    static func run(
        authService: StubAuthService = StubAuthService(),
        userService: StubUserService = StubUserService(),
        _ test: @escaping @Sendable (any TestClientProtocol) async throws -> Void
    ) async throws {
        let authTransport = InProcessTransport()
        let usersTransport = InProcessTransport()
        try await withGRPCServer(transport: authTransport.server, services: [authService]) { _ in
            try await withGRPCServer(transport: usersTransport.server, services: [userService]) { _ in
                try await withGRPCClient(transport: authTransport.client) { authGRPCClient in
                    try await withGRPCClient(transport: usersTransport.client) { usersGRPCClient in
                        let authenticator = MockAuthenticator(identities: ["valid-token": identity])
                        let authClient = Harbor_Auth_V1_AuthService.Client(wrapping: authGRPCClient)
                        let userClient = Harbor_Users_V1_UserService.Client(wrapping: usersGRPCClient)
                        let api = HarborAPI(
                            authenticator: authenticator,
                            authClient: authClient,
                            userClient: userClient
                        )
                        let router = Router(context: BasicRequestContext.self)
                        router.add(middleware: ErrorMiddleware())
                        api.addRoutes(to: router.group("v1"))
                        let application = Application(router: router)
                        try await application.test(.router, test)
                    }
                }
            }
        }
    }
}
