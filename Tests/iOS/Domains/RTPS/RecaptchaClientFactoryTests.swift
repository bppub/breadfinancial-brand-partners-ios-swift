import Testing
@testable import BreadPartners
@preconcurrency import RecaptchaEnterprise

@Suite struct RecaptchaClientFactoryTests {
    private enum TestError: Error {
        case executionFailed
    }

    private actor ClientSpy: RecaptchaVendorClient {
        private(set) var actions: [RecaptchaAction] = []
        private(set) var timeouts: [Double] = []
        let result: Result<String, TestError>

        init(result: Result<String, TestError>) {
            self.result = result
        }

        func execute(
            withAction action: RecaptchaAction,
            withTimeout timeout: Double
        ) async throws -> String {
            actions.append(action)
            timeouts.append(timeout)
            return try result.get()
        }
    }

    @Test
    func executeForwardsActionAndTimeoutAndReturnsToken() async throws {
        let client = ClientSpy(result: .success("token-123"))
        let liveClient = LiveRecaptchaClient(client: client)

        let token = try await liveClient.execute(
            action: "checkout",
            timeout: 5000
        )

        #expect(token == "token-123")
        #expect(await client.actions.count == 1)
        #expect(await client.timeouts == [5000])
    }

    @Test
    func executePropagatesClientErrors() async {
        let client = ClientSpy(result: .failure(.executionFailed))
        let liveClient = LiveRecaptchaClient(client: client)

        do {
            _ = try await liveClient.execute(
                action: "checkout",
                timeout: 10000
            )
            Issue.record("Expected the client error to be propagated")
        } catch TestError.executionFailed {
            #expect(await client.actions.count == 1)
            #expect(await client.timeouts == [10000])
        } catch {
            Issue.record("Received an unexpected error: \(error)")
        }
    }
}
