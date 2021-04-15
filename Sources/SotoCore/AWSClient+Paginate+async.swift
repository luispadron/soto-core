//===----------------------------------------------------------------------===//
//
// This source file is part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if compiler(>=5.5) && $AsyncAwait

import Logging
import NIO

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *)
extension AWSClient {
    /// Used to access paginated results.
    public struct PaginatorSequence<Input: AWSPaginateToken, Output: AWSShape>: AsyncSequence where Input.Token: Equatable {
        public typealias Element = Output
        let input: Input
        let command: (Input, Logger, EventLoop?) async throws -> Output
        let inputKey: KeyPath<Input, Input.Token?>?
        let outputKey: KeyPath<Output, Input.Token?>
        let moreResultsKey: KeyPath<Output, Bool?>?
        let logger: Logger
        let eventLoop: EventLoop?

        /// Initialize PaginatorSequence
        /// - Parameters:
        ///   - input: Initial Input value
        ///   - command: Command to be paginated
        ///   - tokenKey: KeyPath for Output token used to setup new Input
        ///   - logger: Logger
        ///   - eventLoop: EventLoop to run everything on
        public init(
            input: Input,
            command: @escaping ((Input, Logger, EventLoop?) async throws -> Output),
            inputKey: KeyPath<Input, Input.Token?>? = nil,
            outputKey: KeyPath<Output, Input.Token?>,
            moreResultsKey: KeyPath<Output, Bool?>? = nil,
            logger: Logger = AWSClient.loggingDisabled,
            on eventLoop: EventLoop? = nil
        ) {
            self.input = input
            self.command = command
            self.outputKey = outputKey
            self.inputKey = inputKey
            self.moreResultsKey = moreResultsKey
            self.logger = AWSClient.loggingDisabled
            self.eventLoop = eventLoop
        }

        /// Iterator for iterating over `PaginatorSequence`
        public struct AsyncIterator: AsyncIteratorProtocol {
            var input: Input?
            let sequence: PaginatorSequence

            init(sequence: PaginatorSequence) {
                self.sequence = sequence
                self.input = sequence.input
            }

            public mutating func next() async throws -> Output? {
                if let input = input {
                    let output = try await self.sequence.command(input, self.sequence.logger, self.sequence.eventLoop)
                    if let token = output[keyPath: sequence.outputKey],
                       sequence.inputKey == nil || token != input[keyPath: sequence.inputKey!],
                       sequence.moreResultsKey == nil || output[keyPath: sequence.moreResultsKey!] == true
                    {
                        self.input = input.usingPaginationToken(token)
                    } else {
                        self.input = nil
                    }
                    return output
                }
                return nil
            }
        }

        /// Make async iterator
        public func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(sequence: self)
        }

        @inlinable
        public func reduce<Result>(
          _ initialResult: Result,
          _ nextPartialResult:
            (_ partialResult: Result, Element) async throws -> Result
        ) async throws -> Result {
          var accumulator = initialResult
          var iterator = makeAsyncIterator()
          while let element = try await iterator.next() {
            accumulator = try await nextPartialResult(accumulator, element)
          }
          return accumulator
        }

        @inlinable
        public func reduce<Result>(
          into initialResult: __owned Result,
          _ updateAccumulatingResult:
            (_ partialResult: inout Result, Element) async throws -> Void
        ) async throws -> Result {
          var accumulator = initialResult
          var iterator = makeAsyncIterator()
          while let element = try await iterator.next() {
            try await updateAccumulatingResult(&accumulator, element)
          }
          return accumulator
        }
    }
}

#endif // compiler(>=5.5) && $AsyncAwait
