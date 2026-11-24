import AuthProtos
import GRPCCore
import SwiftProtobuf

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Auth's public contract, answering fixed values or the error it was given.
struct StubAuthService: Harbor_Auth_V1_AuthService.SimpleServiceProtocol {
    var error: RPCError?

    func register(
        request: Harbor_Auth_V1_RegisterRequest,
        context: ServerContext
    ) async throws -> Harbor_Auth_V1_Account {
        if let error {
            throw error
        }

        return Harbor_Auth_V1_Account.with {
            $0.id = "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b"
            $0.email = request.email
            $0.status = .pendingVerification
            $0.creationDate = Google_Protobuf_Timestamp(date: .now)
        }
    }

    func verifyEmail(
        request: Harbor_Auth_V1_VerifyEmailRequest,
        context: ServerContext
    ) async throws -> Google_Protobuf_Empty {
        if let error {
            throw error
        }

        return Google_Protobuf_Empty()
    }

    func signIn(request: Harbor_Auth_V1_SignInRequest, context: ServerContext) async throws -> Harbor_Auth_V1_Session {
        if let error {
            throw error
        }

        return Harbor_Auth_V1_Session.with {
            $0.accessToken = "access"
            $0.accessTokenExpirationDate = Google_Protobuf_Timestamp(date: .now)
            $0.refreshToken = "refresh"
        }
    }

    func refreshSession(
        request: Harbor_Auth_V1_RefreshSessionRequest,
        context: ServerContext
    ) async throws -> Harbor_Auth_V1_Session {
        try await signIn(request: Harbor_Auth_V1_SignInRequest(), context: context)
    }

}
