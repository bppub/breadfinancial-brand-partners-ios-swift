import Testing
@testable import BreadPartners
@preconcurrency import RecaptchaEnterprise

@Suite struct RecaptchaClientFactoryTests {
    private enum TestError: Error {
        case executionFailed
    }

    private struct ClientStub: RecaptchaVendorClient {
        func execute(
            withAction action: RecaptchaAction,
            withTimeout timeout: Double
        ) async throws -> String {
            "token-123"
        }
    }

    private actor ClientLoaderSpy: RecaptchaClientLoader {
        let client: any RecaptchaVendorClient
        let error: TestError?
        private(set) var siteKeys: [String] = []

        init(client: any RecaptchaVendorClient, error: TestError? = nil) {
            self.client = client
            self.error = error
        }

        func fetchClient(siteKey: String) async throws -> any RecaptchaVendorClient {
            siteKeys.append(siteKey)
            if let error {
                throw error
            }
            return client
        }
    }

    @Test
    func factoryForwardsSiteKeyAndReturnsClient() async throws {
        let client = ClientStub()
        let loader = ClientLoaderSpy(client: client)
        let factory = LiveRecaptchaClientFactory(clientLoader: loader)

        let result = try await factory.makeClient(siteKey: "site-key")

        #expect(await loader.siteKeys == ["site-key"])
        guard let result else {
            Issue.record("Expected the factory to return a client")
            return
        }
        _ = result
    }

    @Test
    func factoryPropagatesClientCreationErrors() async {
        let client = ClientStub()
        let loader = ClientLoaderSpy(client: client, error: .executionFailed)
        let factory = LiveRecaptchaClientFactory(clientLoader: loader)

        do {
            _ = try await factory.makeClient(siteKey: "site-key")
            Issue.record("Expected the client creation error to be propagated")
        } catch TestError.executionFailed {
            #expect(await loader.siteKeys == ["site-key"])
        } catch {
            Issue.record("Received an unexpected error: \(error)")
        }
    }
}
