//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2020-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5)

import struct Foundation.URL
import NIOCore

/// Protocol for services objects. Contains a client to communicate with AWS and config for defining how to communicate
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
extension AWSService {
    /// Generate a signed URL
    /// - parameters:
    ///     - url : URL to sign
    ///     - httpMethod: HTTP method to use (.GET, .PUT, .PUSH etc)
    ///     - headers: Headers that are to be used with this URL. Be sure to include these headers when you used the returned URL
    ///     - expires: How long before the signed URL expires
    ///     - logger: Logger to output to
    /// - returns:
    ///     A signed URL
    public func signURL(
        url: URL,
        httpMethod: HTTPMethod,
        headers: HTTPHeaders = HTTPHeaders(),
        expires: TimeAmount,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> URL {
        return try await self.client.signURL(url: url, httpMethod: httpMethod, headers: headers, expires: expires, serviceConfig: self.config, logger: logger)
    }

    /// Generate signed headers
    /// - parameters:
    ///     - url : URL to sign
    ///     - httpMethod: HTTP method to use (.GET, .PUT, .PUSH etc)
    ///     - headers: Headers that are to be used with this URL. Be sure to include these headers when you used the returned URL
    ///     - body: body payload to sign as well. While it is unnecessary to provide the body for S3 other services require it
    ///     - logger: Logger to output to
    /// - returns:
    ///     A series of signed headers including the original headers provided to the function
    public func signHeaders(
        url: URL,
        httpMethod: HTTPMethod,
        headers: HTTPHeaders = HTTPHeaders(),
        body: AWSPayload = .empty,
        logger: Logger = AWSClient.loggingDisabled
    ) async throws -> HTTPHeaders {
        return try await self.client.signHeaders(url: url, httpMethod: httpMethod, headers: headers, body: body, serviceConfig: self.config, logger: logger)
    }
}

#endif // compiler(>=5.5)
