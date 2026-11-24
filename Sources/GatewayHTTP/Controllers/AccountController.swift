package import AuthProtos
package import Hummingbird

/// The `/v1/account` resource: registering, verifying the address, signing in and refreshing.
package struct AccountController: Sendable {
    private let client: any Harbor_Auth_V1_AuthService.ClientProtocol

    package init(client: any Harbor_Auth_V1_AuthService.ClientProtocol) {
        self.client = client
    }

    /// Wired at `account`. Every route here proves itself with its body, so none needs a caller.
    package func addPublicRoutes(to group: RouterGroup<BasicRequestContext>) {
        group
            .post(use: register)
            .post("verify-email", use: verifyEmail)
            .post("sign-in", use: signIn)
            .post("refresh", use: refreshSession)
    }

    private func register(
        request: Request,
        context: BasicRequestContext
    ) async throws -> EditedResponse<Components.Schemas.AccountResponse> {
        let idempotencyKey = try request.headers.requireIdempotencyKey()
        let body = try await request.decode(as: Components.Schemas.RegisterRequest.self, context: context)
        let registerRequest = Harbor_Auth_V1_RegisterRequest(body, idempotencyKey: idempotencyKey)
        let account = try await client.register(registerRequest)
        let response = try Components.Schemas.AccountResponse(account)
        return EditedResponse(status: .created, response: response)
    }

    private func verifyEmail(request: Request, context: BasicRequestContext) async throws -> HTTPResponse.Status {
        let body = try await request.decode(as: Components.Schemas.VerifyEmailRequest.self, context: context)
        let verifyEmailRequest = Harbor_Auth_V1_VerifyEmailRequest(body)
        _ = try await client.verifyEmail(verifyEmailRequest)
        return .noContent
    }

    private func signIn(
        request: Request,
        context: BasicRequestContext
    ) async throws -> Components.Schemas.SessionResponse {
        let body = try await request.decode(as: Components.Schemas.SignInRequest.self, context: context)
        let signInRequest = Harbor_Auth_V1_SignInRequest(body)
        let session = try await client.signIn(signInRequest)
        return try Components.Schemas.SessionResponse(session)
    }

    private func refreshSession(
        request: Request,
        context: BasicRequestContext
    ) async throws -> Components.Schemas.SessionResponse {
        let body = try await request.decode(as: Components.Schemas.RefreshSessionRequest.self, context: context)
        let refreshSessionRequest = Harbor_Auth_V1_RefreshSessionRequest(body)
        let session = try await client.refreshSession(refreshSessionRequest)
        return try Components.Schemas.SessionResponse(session)
    }
}
