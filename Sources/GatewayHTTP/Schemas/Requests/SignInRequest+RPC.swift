import AuthProtos

extension Harbor_Auth_V1_SignInRequest {
    init(_ body: Components.Schemas.SignInRequest) {
        self.init()
        self.email = body.email
        self.password = body.password
    }
}
