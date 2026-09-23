import Foundation

@testable import BreadPartnersCore

actor StubRecaptchaProvider: RecaptchaProviding {
    private let result: Result<String, NSError>

    private(set) var callCount = 0
    private(set) var lastSiteKey: String?
    private(set) var lastAction: String?
    private(set) var lastTimeout: Double?
    private(set) var lastDebug: Bool?

    init(result: Result<String, NSError> = .success("recaptcha-token")) {
        self.result = result
    }

    func execute(siteKey: String, action: String, timeout: Double, debug: Bool) async throws -> String {
        callCount += 1
        lastSiteKey = siteKey
        lastAction = action
        lastTimeout = timeout
        lastDebug = debug

        switch result {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        }
    }
}

actor SpyRTPSNetworkClient: HTTPClient {
    private let responseData: Data
    private let failure: NSError?

    private(set) var requests: [HTTPRequest] = []

    init(responseData: Data = Data(), failure: NSError? = nil) {
        self.responseData = responseData
        self.failure = failure
    }

    func request(_ request: HTTPRequest) async throws -> Data {
        requests.append(request)

        if let failure {
            throw failure
        }

        return responseData
    }
}

/// `RTPSRequestBuilding.build` is synchronous, so the stub locks while recording tokens.
final class StubRTPSRequestBuilder: RTPSRequestBuilding, @unchecked Sendable {
    private let lock = NSLock()
    private var tokens: [String?] = []
    private let request: RTPSRequest

    init(request: RTPSRequest = RTPSRequest()) {
        self.request = request
    }

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

        return request
    }
}

struct StubRTPSResponseDecoder: RTPSResponseDecoding {
    let response: RTPSResponse
    var failure: NSError?

    init(
        response: RTPSResponse = RTPSFixtures.Response.neutral(),
        failure: NSError? = nil
    ) {
        self.response = response
        self.failure = failure
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if let failure {
            throw failure
        }

        guard type == RTPSResponse.self, let response = response as? T else {
            throw NSError(
                domain: "StubRTPSResponseDecoder",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No response configured"]
            )
        }

        return response
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
        static func neutral() -> RTPSResponse {
            RTPSResponse()
        }

        static func approved(
            prescreenId: Int64 = 9001,
            cardType: String = "storeCard"
        ) -> RTPSResponse {
            RTPSResponse(
                returnCode: "01",
                prescreenId: prescreenId,
                cardType: cardType
            )
        }

        static func model(
            returnCode: String? = "01",
            prescreenId: Int64? = 9001,
            cardType: String? = "storeCard"
        ) -> RTPSResponse {
            RTPSResponse(
                returnCode: returnCode,
                prescreenId: prescreenId,
                cardType: cardType
            )
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
        isLoggingEnabled: Bool = false,
        log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> RTPSServiceInput {
        RTPSServiceInput(
            merchantConfiguration: merchantConfiguration,
            rtpsData: rtpsData,
            integrationKey: integrationKey,
            siteKey: siteKey,
            prescreenURL: URLs.prescreen,
            virtualLookupURL: URLs.virtualLookup,
            cookies: cookies,
            isLoggingEnabled: isLoggingEnabled,
            log: log
        )
    }

    static func dependencies(
        recaptcha: StubRecaptchaProvider = StubRecaptchaProvider(),
        network: SpyRTPSNetworkClient = SpyRTPSNetworkClient(),
        requestBuilder: StubRTPSRequestBuilder = StubRTPSRequestBuilder(),
        responseDecoder: StubRTPSResponseDecoder = StubRTPSResponseDecoder()
    ) -> RTPSDependencies {
        RTPSDependencies(
            recaptcha: recaptcha,
            httpClient: network,
            requestBuilder: requestBuilder,
            responseDecoder: responseDecoder
        )
    }
}
