// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthProtos

extension Harbor_Auth_V1_RegisterRequest {
    init(_ body: Components.Schemas.RegisterRequest, idempotencyKey: String) {
        self.init()
        self.email = body.email
        self.password = body.password
        self.displayName = body.displayName
        self.idempotencyKey = idempotencyKey
    }
}
