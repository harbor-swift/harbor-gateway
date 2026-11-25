// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import AuthProtos
package import Authentication
import AuthenticationHummingbird
package import HarborAuthentication
package import Hummingbird
import HummingbirdAuth
package import UsersProtos

/// The whole HTTP surface, built from the clients it needs and nothing else.
package struct HarborAPI: Sendable {
    private let authenticator: any Authenticator<String, UserIdentity>
    private let authClient: any Harbor_Auth_V1_AuthService.ClientProtocol
    private let userClient: any Harbor_Users_V1_UserService.ClientProtocol

    package init(
        authenticator: any Authenticator<String, UserIdentity>,
        authClient: any Harbor_Auth_V1_AuthService.ClientProtocol,
        userClient: any Harbor_Users_V1_UserService.ClientProtocol
    ) {
        self.authenticator = authenticator
        self.authClient = authClient
        self.userClient = userClient
    }

    /// Wired at `v1`.
    package func addRoutes(to group: RouterGroup<BasicRequestContext>) {
        let accountController = AccountController(client: authClient)
        let userController = UserController(client: userClient)

        // MARK: - No caller

        accountController.addPublicRoutes(to: group.group("account"))

        // MARK: - A caller

        let bearerAuthentication = BearerAuthenticationMiddleware<IdentityRequestContext>(authenticator: authenticator)
        let authenticated =
            group
            .group(context: IdentityRequestContext.self)
            .add(middleware: bearerAuthentication)
            .add(middleware: IsAuthenticatedMiddleware())

        userController.addAuthenticatedRoutes(to: authenticated.group("users"))
    }
}
