import AuthProtos

extension Harbor_Auth_V1_VerifyEmailRequest {
    init(_ body: Components.Schemas.VerifyEmailRequest) {
        self.init()
        self.token = body.token
    }
}
