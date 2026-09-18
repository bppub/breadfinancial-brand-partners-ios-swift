import Foundation

@testable import BreadPartnersCore

actor StubRecaptchaProvider: RecaptchaProviding {
    private let token: String
    private let failure: NSError?

    private(set) var callCount = 0
    private(set) var lastSiteKey: String?
    private(set) var lastAction: String?
    private(set) var lastTimeout: Double?
    private(set) var lastDebug: Bool?

    init(token: String = "recaptcha-token", failure: NSError? = nil) {
        self.token = token
        self.failure = failure
    }

    func execute(siteKey: String, action: String, timeout: Double, debug: Bool) async throws -> String {
        callCount += 1
        lastSiteKey = siteKey
        lastAction = action
        lastTimeout = timeout
        lastDebug = debug

        if let failure {
            throw failure
        }

        return token
    }
}

actor SpyRTPSNetworkClient: RTPSNetworkClient {
    private let responseData: Data
    private let failure: NSError?

    private(set) var requests: [RTPSNetworkRequest] = []

    init(responseData: Data = Data(), failure: NSError? = nil) {
        self.responseData = responseData
        self.failure = failure
    }

    func send(_ request: RTPSNetworkRequest) async throws -> Data {
        requests.append(request)

        if let failure {
            throw failure
        }

        return responseData
    }
}

/// `RTPSRequestBuilding.build` is synchronous, so the spy locks instead of using actor isolation.
final class SpyRTPSRequestBuilder: RTPSRequestBuilding, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: [String?] = []

    var receivedTokens: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return tokens
    }

    func build(
        merchantConfiguration: MerchantConfiguration,
        rtpsData: RTPSData,
        recaptchaToken: String?
    ) -> RTPSRequest {
        lock.lock()
        tokens.append(recaptchaToken)
        lock.unlock()

        return RTPSRequestBuilder().build(
            merchantConfiguration: merchantConfiguration,
            rtpsData: rtpsData,
            recaptchaToken: recaptchaToken
        )
    }
}

/// Decodes real JSON so `RTPSResponse` parsing stays exercised, or throws a preset failure.
struct StubRTPSResponseDecoder: RTPSResponseDecoding {
    var failure: NSError?

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if let failure {
            throw failure
        }

        return try JSONDecoder().decode(type, from: data)
    }
}

enum RTPSFixtures {
    enum URLs {
        static let prescreen = URL(string: "https://rtps.test/api/prescreen")!
        static let virtualLookup = URL(string: "https://rtps.test/api/virtual_lookup")!
    }

    enum MerchantConfigurationFixture {
        enum RequiredField: String, CaseIterable, Sendable {
            case givenName
            case familyName
            case address1
            case country
            case locality
            case region
            case postalCode
        }

        static func complete() -> MerchantConfiguration {
            MerchantConfiguration(
                buyer: BreadPartnersBuyer(
                    givenName: "Ada",
                    familyName: "Lovelace",
                    billingAddress: BreadPartnersAddress(
                        address1: "1 Main St",
                        country: "US",
                        locality: "Columbus",
                        region: "OH",
                        postalCode: "43004"
                    )
                )
            )
        }

        static func missing(_ field: RequiredField) -> MerchantConfiguration {
            var configuration = complete()
            var buyer = configuration.buyer
            var address = buyer?.billingAddress

            switch field {
            case .givenName: buyer?.givenName = ""
            case .familyName: buyer?.familyName = ""
            case .address1: address?.address1 = ""
            case .country: address?.country = ""
            case .locality: address?.locality = ""
            case .region: address?.region = ""
            case .postalCode: address?.postalCode = ""
            }

            buyer?.billingAddress = address
            configuration.buyer = buyer
            return configuration
        }
    }

    enum Response {
        static func json(
            returnCode: String? = "01",
            prescreenId: Int64? = 9001,
            cardType: String? = "storeCard"
        ) -> Data {
            var payload: [String: Any] = [:]
            payload["returnCode"] = returnCode
            payload["prescreenId"] = prescreenId
            payload["cardType"] = cardType
            return (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
        }
    }

    enum Error {
        static func incapsula(
            htmlContent: String? = "<html>challenge</html>",
            url: String? = "https://challenge.test"
        ) -> NSError {
            var userInfo: [String: Any] = [:]
            userInfo["htmlContent"] = htmlContent
            userInfo["url"] = url
            return NSError(domain: "IncapsulaChallenge", code: 0, userInfo: userInfo)
        }
    }

    static func input(
        merchantConfiguration: MerchantConfiguration = MerchantConfigurationFixture.complete(),
        rtpsData: RTPSData,
        integrationKey: String = "integration-key",
        siteKey: String = "site-key",
        cookies: String? = nil,
        isLoggingEnabled: Bool = false
    ) -> RTPSServiceInput {
        RTPSServiceInput(
            merchantConfiguration: merchantConfiguration,
            rtpsData: rtpsData,
            integrationKey: integrationKey,
            siteKey: siteKey,
            prescreenURL: URLs.prescreen,
            virtualLookupURL: URLs.virtualLookup,
            cookies: cookies,
            isLoggingEnabled: isLoggingEnabled
        )
    }

    static func dependencies(
        recaptcha: StubRecaptchaProvider = StubRecaptchaProvider(),
        network: SpyRTPSNetworkClient = SpyRTPSNetworkClient(),
        requestBuilder: SpyRTPSRequestBuilder = SpyRTPSRequestBuilder(),
        responseDecoder: StubRTPSResponseDecoder = StubRTPSResponseDecoder()
    ) -> RTPSDependencies {
        RTPSDependencies(
            recaptcha: recaptcha,
            network: network,
            requestBuilder: requestBuilder,
            responseDecoder: responseDecoder
        )
    }
}
