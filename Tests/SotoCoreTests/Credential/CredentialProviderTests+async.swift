//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2021 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5)

import _NIOConcurrency
import NIO
import SotoCore
import SotoTestUtils
import XCTest

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class AsyncCredentialProviderTests: XCTestCase {
    func testAsyncCredentialProvider() {
        struct TestAsyncProvider: AsyncCredentialProvider {
            func getCredential(on eventLoop: EventLoop, logger: Logger) async throws -> Credential {
                return StaticCredential(accessKeyId: "abc", secretAccessKey: "123", sessionToken: "xyz")
            }
        }
        let client = AWSClient(
            credentialProvider: .custom { _ in TestAsyncProvider() },
            httpClientProvider: .createNew
        )
        defer { XCTAssertNoThrow(try client.syncShutdown()) }
        let credentialsFuture = client.credentialProvider.getCredential(
            on: client.eventLoopGroup.next(),
            logger: TestEnvironment.logger
        ).map { credential in
            XCTAssertEqual(credential.accessKeyId, "abc")
            XCTAssertEqual(credential.secretAccessKey, "123")
        }
        XCTAssertNoThrow(try credentialsFuture.wait())
    }
}

#endif // compiler(>=5.5)
