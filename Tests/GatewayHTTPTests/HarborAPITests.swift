// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import GRPCCore
import GatewayHTTP
import HTTPTypes
import Hummingbird
import HummingbirdTesting
import NIOCore
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("HarborAPI")
struct HarborAPITests {
    private let registerBody = ByteBuffer(
        string: #"{"email": "ada@example.com", "password": "correct horse battery", "displayName": "Ada"}"#
    )

    /// A top-level field of a response body: Harbor's responses hold strings, numbers, Booleans and nulls.
    private enum Field: Decodable, Equatable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case null

        var string: String? {
            guard case .string(let value) = self else { return nil }
            return value
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
                return
            }
            do {
                self = .string(try container.decode(String.self))
            } catch DecodingError.typeMismatch {
                do {
                    self = .bool(try container.decode(Bool.self))
                } catch DecodingError.typeMismatch {
                    self = .number(try container.decode(Double.self))
                }
            }
        }
    }

    private func json(_ response: TestResponse) throws -> [String: Field] {
        let data = Data(response.body.readableBytesView)
        return try JSONDecoder().decode([String: Field].self, from: data)
    }

    // MARK: - No caller

    @Test("Register answers 201 with the account")
    func registers() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/account",
                method: .post,
                headers: [.contentType: "application/json", .idempotencyKey: "key-1"],
                body: registerBody
            ) { response in
                #expect(response.status == .created)
                let account = try json(response)
                #expect(account["status"]?.string == "pendingVerification")
                #expect(account["email"]?.string == "ada@example.com")
            }
        }
    }

    @Test("Register without an Idempotency-Key answers 400 problem details")
    func requiresIdempotencyKey() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/account",
                method: .post,
                headers: [.contentType: "application/json"],
                body: registerBody
            ) { response in
                #expect(response.status == .badRequest)
                #expect(response.headers[.contentType] == "application/problem+json")
                let problem = try json(response)
                #expect(problem["detail"]?.string == "The Idempotency-Key header is required.")
                #expect(problem["instance"]?.string?.hasPrefix("urn:harbor:request:") == true)
            }
        }
    }

    @Test("An upstream refusal answers its status with the service's message")
    func mapsUpstreamRefusal() async throws {
        let error = RPCError(code: .alreadyExists, message: "The email address is already registered.")
        try await TestGateway.run(authService: StubAuthService(error: error)) { client in
            try await client.execute(
                uri: "/v1/account",
                method: .post,
                headers: [.contentType: "application/json", .idempotencyKey: "key-1"],
                body: registerBody
            ) { response in
                #expect(response.status == .conflict)
                let problem = try json(response)
                #expect(problem["detail"]?.string == "The email address is already registered.")
            }
        }
    }

    @Test("Verifying an address answers 204")
    func verifiesEmail() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/account/verify-email",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: #"{"token": "token"}"#)
            ) { response in
                #expect(response.status == .noContent)
            }
        }
    }

    @Test("Signing in answers bearer tokens")
    func signsIn() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/account/sign-in",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: #"{"email": "ada@example.com", "password": "correct horse battery"}"#)
            ) { response in
                #expect(response.status == .ok)
                let session = try json(response)
                #expect(session["tokenType"]?.string == "Bearer")
                #expect(session["accessToken"]?.string == "access")
                #expect(session["refreshToken"]?.string == "refresh")
            }
        }
    }

    // MARK: - A caller

    @Test("Reading the caller's user needs a token")
    func requiresToken() async throws {
        try await TestGateway.run { client in
            try await client.execute(uri: "/v1/users/me", method: .get) { response in
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("An invalid token is refused before any upstream call")
    func refusesInvalidToken() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/users/me",
                method: .get,
                headers: [.authorization: "Bearer forged-token"]
            ) { response in
                #expect(response.status == .unauthorized)
            }
        }
    }

    @Test("A caller reads their own user")
    func readsUser() async throws {
        try await TestGateway.run { client in
            try await client.execute(
                uri: "/v1/users/me",
                method: .get,
                headers: [.authorization: "Bearer valid-token"]
            ) { response in
                #expect(response.status == .ok)
                let user = try json(response)
                #expect(user["id"]?.string == "0193a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b")
                #expect(user["displayName"]?.string == "Ada")
                #expect(user["email"] == nil)
            }
        }
    }

    @Test("An upstream outage answers 503 without the transport's message")
    func hidesServerErrors() async throws {
        let error = RPCError(code: .unavailable, message: "connection refused to users:50052")
        try await TestGateway.run(userService: StubUserService(error: error)) { client in
            try await client.execute(
                uri: "/v1/users/me",
                method: .get,
                headers: [.authorization: "Bearer valid-token"]
            ) { response in
                #expect(response.status == .serviceUnavailable)
                let problem = try json(response)
                #expect(problem["detail"] == nil)
            }
        }
    }
}
