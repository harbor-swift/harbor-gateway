// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import HTTPTypes
import Hummingbird

extension HTTPField.Name {
    /// The IETF `Idempotency-Key` header a client repeats on every retry of a create.
    package static let idempotencyKey = HTTPField.Name("Idempotency-Key")!
}

extension HTTPFields {
    /// The request's idempotency key, or `400` when it has none.
    func requireIdempotencyKey() throws -> String {
        guard let idempotencyKey = self[.idempotencyKey], !idempotencyKey.isEmpty else {
            throw HTTPError(.badRequest, message: "The Idempotency-Key header is required.")
        }

        return idempotencyKey
    }
}
