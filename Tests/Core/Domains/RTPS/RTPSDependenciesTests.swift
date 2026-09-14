import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSDependenciesTests {
    private struct Recaptcha: RecaptchaProviding {
        func execute(siteKey: String, action: String, timeout: Double, debug: Bool) async throws -> String { "token" }
    }

    private struct Network: RTPSNetworkClient {
        func send(_ request: RTPSNetworkRequest) async throws -> RTPSNetworkResponse {
            RTPSNetworkResponse(data: Data(), statusCode: 200)
        }
    }

    private struct Builder: RTPSRequestBuilding {
        func build(merchantConfiguration: MerchantConfiguration, rtpsData: RTPSData, recaptchaToken: String?)
            -> RTPSRequest
        {
            RTPSRequest()
        }
    }

    private struct Decoder: RTPSResponseDecoding {
        func decode<T: Decodable>(_ type: T.Type, from response: RTPSNetworkResponse) throws -> T {
            fatalError("unused")
        }
    }

    @Test
    func storesInjectedDependencies() {
        let dependencies = RTPSDependencies(
            recaptcha: Recaptcha(),
            network: Network(),
            requestBuilder: Builder(),
            responseDecoder: Decoder()
        )

        #expect(dependencies.recaptcha is Recaptcha)
        #expect(dependencies.network is Network)
        #expect(dependencies.requestBuilder is Builder)
        #expect(dependencies.responseDecoder is Decoder)
    }
}
