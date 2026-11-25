// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Hummingbird
import SwiftProtobuf
import UsersProtos

extension Components.Schemas.UserResponse: ResponseEncodable {
    init(_ user: Harbor_Users_V1_User) throws {
        guard user.hasCreationDate else {
            throw UpstreamValueError(field: "creation_date")
        }

        self.init(id: user.id, displayName: user.displayName, creationDate: user.creationDate.date)
    }
}
