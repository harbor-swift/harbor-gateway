// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

package import Hummingbird
import NIOCore

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// RFC 9457 problem details. Without a `type`, a problem means what its status means.
package struct Problem: HTTPResponseError {
    package let status: HTTPResponse.Status
    package let detail: String?
    package let headers: HTTPFields

    package init(status: HTTPResponse.Status, detail: String? = nil, headers: HTTPFields = [:]) {
        self.status = status
        self.detail = detail
        self.headers = headers
    }

    package func response(from request: Request, context: some RequestContext) throws -> Response {
        // The request's id is on every log line it wrote, so a reported problem names its trace.
        let body = Body(
            title: status.reasonPhrase,
            status: status.code,
            detail: detail,
            instance: "urn:harbor:request:\(context.id)"
        )
        let json = try JSONEncoder().encode(body)
        let buffer = ByteBuffer(bytes: json)
        var headers = self.headers
        headers[.contentType] = "application/problem+json"
        return Response(status: status, headers: headers, body: ResponseBody(byteBuffer: buffer))
    }

    private struct Body: Encodable {
        let title: String
        let status: Int
        let detail: String?
        let instance: String
    }
}
