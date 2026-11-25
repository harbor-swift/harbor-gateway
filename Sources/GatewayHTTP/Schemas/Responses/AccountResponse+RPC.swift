// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthProtos
import Hummingbird
import SwiftProtobuf

extension Components.Schemas.AccountResponse: ResponseEncodable {
    init(_ account: Harbor_Auth_V1_Account) throws {
        guard account.hasCreationDate else {
            throw UpstreamValueError(field: "creation_date")
        }

        let status = try Components.Schemas.AccountStatus(account.status)
        self.init(id: account.id, email: account.email, status: status, creationDate: account.creationDate.date)
    }
}

extension Components.Schemas.AccountStatus {
    init(_ status: Harbor_Auth_V1_AccountStatus) throws {
        switch status {
        case .pendingVerification:
            self = .pendingVerification
        case .active:
            self = .active
        case .unspecified, .UNRECOGNIZED:
            throw UpstreamValueError(field: "status")
        }
    }
}
