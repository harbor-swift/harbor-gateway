// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthProtos

extension Harbor_Auth_V1_RefreshSessionRequest {
    init(_ body: Components.Schemas.RefreshSessionRequest) {
        self.init()
        self.refreshToken = body.refreshToken
    }
}
