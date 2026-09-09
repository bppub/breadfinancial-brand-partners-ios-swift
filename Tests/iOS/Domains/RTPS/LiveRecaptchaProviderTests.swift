import Testing
@testable import BreadPartners

@Suite struct LiveRecaptchaProviderTests {
    private enum TestError: Error {
        case executionFailed
    }

    private actor ClientSpy: RecaptchaClientProviding {
        let result: Result<String, TestError>
        private(set) var actions: [String] = []
        private(set) var timeouts: [Double] = []

        init(result: Result<String, TestError>) {
            self.result = result
        }

        func execute(action: String, timeout: Double) async throws -> String {
            actions.append(action)
            timeouts.append(timeout)
            return try result.get()
        }
    }

    private actor FactorySpy: RecaptchaClientFactory {
        let client: ClientSpy?
        private(set) var siteKeys: [String] = []

        init(client: ClientSpy?) {
            self.client = client
        }

        func makeClient(siteKey: String) async throws -> (any RecaptchaClientProviding)? {
            siteKeys.append(siteKey)
            return client
        }
    }

    private final class EventBox: @unchecked Sendable {
        var events: [BreadPartnerEvents] = []
    }

    @Test
    func executeForwardsActionTimeoutAndReturnsToken() async throws {
        let client = ClientSpy(result: .success("token-123"))
        let factory = FactorySpy(client: client)
        let provider = LiveRecaptchaProvider(clientFactory: factory)

        let token = try await provider.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 5000,
            debug: false
        )

        #expect(token == "token-123")
        #expect(await factory.siteKeys == ["site-key"])
        #expect(await client.actions == ["checkout"])
        #expect(await client.timeouts == [5000])
    }

    @Test
    func executeReturnsEmptyTokenWhenClientIsUnavailable() async throws {
        let factory = FactorySpy(client: nil)
        let provider = LiveRecaptchaProvider(clientFactory: factory)

        let token = try await provider.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10000,
            debug: false
        )

        #expect(token.isEmpty)
        #expect(await factory.siteKeys == ["site-key"])
    }

    @Test
    func executeReusesClientForSubsequentCalls() async throws {
        let client = ClientSpy(result: .success("token"))
        let factory = FactorySpy(client: client)
        let provider = LiveRecaptchaProvider(clientFactory: factory)

        _ = try await provider.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10000,
            debug: false
        )
        _ = try await provider.execute(
            siteKey: "different-site-key",
            action: "second-action",
            timeout: 5000,
            debug: false
        )

        #expect(await factory.siteKeys == ["site-key"])
        #expect(await client.actions == ["checkout", "second-action"])
        #expect(await client.timeouts == [10000, 5000])
    }

    @Test
    func executePropagatesClientErrors() async {
        let client = ClientSpy(result: .failure(.executionFailed))
        let factory = FactorySpy(client: client)
        let provider = LiveRecaptchaProvider(clientFactory: factory)

        do {
            _ = try await provider.execute(
                siteKey: "site-key",
                action: "checkout",
                timeout: 10000,
                debug: false
            )
            Issue.record("Expected the client error to be propagated")
        } catch TestError.executionFailed {
            #expect(await client.actions == ["checkout"])
        } catch {
            Issue.record("Received an unexpected error: \(error)")
        }
    }

    @Test
    func executeLogsTokenWhenDebugIsEnabled() async throws {
        let client = ClientSpy(result: .success("token-123"))
        let factory = FactorySpy(client: client)
        let events = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { events.events.append($0) }
        let provider = LiveRecaptchaProvider(logger: logger, clientFactory: factory)

        _ = try await provider.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10000,
            debug: true
        )

        #expect(events.events.count == 1)
        guard case let .onSDKEventLog(message)? = events.events.first else {
            Issue.record("Expected a reCAPTCHA token log event")
            return
        }
        #expect(message.contains("token-123"))
    }

    @Test
    func executeDoesNotLogTokenWhenDebugIsDisabled() async throws {
        let client = ClientSpy(result: .success("token-123"))
        let factory = FactorySpy(client: client)
        let events = EventBox()
        let logger = Logger()
        logger.setLogging(enabled: true)
        logger.setCallback { events.events.append($0) }
        let provider = LiveRecaptchaProvider(logger: logger, clientFactory: factory)

        _ = try await provider.execute(
            siteKey: "site-key",
            action: "checkout",
            timeout: 10000,
            debug: false
        )

        #expect(events.events.isEmpty)
    }
}
