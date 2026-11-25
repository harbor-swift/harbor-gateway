// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthProtos

extension Harbor_Auth_V1_SignInRequest {
    init(_ body: Components.Schemas.SignInRequest) {
        self.init()
        self.email = body.email
        self.password = body.password
    }
}
