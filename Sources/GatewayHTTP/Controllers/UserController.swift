// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Hummingbird
package import UsersProtos

/// The `/v1/users` resource: the caller's own user, at `me`.
package struct UserController: Sendable {
    private let client: any Harbor_Users_V1_UserService.ClientProtocol

    package init(client: any Harbor_Users_V1_UserService.ClientProtocol) {
        self.client = client
    }

    /// Wired at `users`. The forwarded token names the caller, so no route sends a user id upstream.
    package func addAuthenticatedRoutes(to group: RouterGroup<IdentityRequestContext>) {
        group.get("me", use: getUser)
    }

    private func getUser(
        request: Request,
        context: IdentityRequestContext
    ) async throws -> Components.Schemas.UserResponse {
        let getUserRequest = Harbor_Users_V1_GetUserRequest()
        let user = try await client.getUser(getUserRequest)
        return try Components.Schemas.UserResponse(user)
    }
}
