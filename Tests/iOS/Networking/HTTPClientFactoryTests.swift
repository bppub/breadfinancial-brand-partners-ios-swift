import Foundation
import Testing
@testable import BreadPartners

struct HTTPClientFactoryTests {
    @Test
    func liveFactoryMakesHTTPClient() {
        let client = LiveHTTPClientFactory().makeClient(logger: Logger())

        #expect(client is LiveHTTPClient)
    }

    @Test
    func liveFactoryDefaultsToSharedSession() {
        let factory = LiveHTTPClientFactory()

        #expect(factory.session === URLSession.shared)
    }

    @Test
    func liveFactoryPersistsInjectedSession() {
        let session = URLSession(configuration: .ephemeral)
        let factory = LiveHTTPClientFactory(session: session)

        #expect(factory.session === session)
    }
}
