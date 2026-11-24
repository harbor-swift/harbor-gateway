import GRPCCore
import SwiftProtobuf
import UsersProtos

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Users' public contract, answering a fixed user or the error it was given.
struct StubUserService: Harbor_Users_V1_UserService.SimpleServiceProtocol {
    var error: RPCError?

    func getUser(
        request: Harbor_Users_V1_GetUserRequest,
        context: ServerContext
    ) async throws -> Harbor_Users_V1_User {
        if let error {
            throw error
        }

        return Harbor_Users_V1_User.with {
            $0.id = "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b"
            $0.displayName = "Ada"
            $0.creationDate = Google_Protobuf_Timestamp(date: .now)
        }
    }
}
