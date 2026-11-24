import AuthProtos
import Hummingbird
import SwiftProtobuf

extension Components.Schemas.SessionResponse: ResponseEncodable {
    init(_ session: Harbor_Auth_V1_Session) throws {
        guard session.hasAccessTokenExpirationDate else {
            throw UpstreamValueError(field: "access_token_expiration_date")
        }

        self.init(
            tokenType: .bearer,
            accessToken: session.accessToken,
            accessTokenExpirationDate: session.accessTokenExpirationDate.date,
            refreshToken: session.refreshToken
        )
    }
}
