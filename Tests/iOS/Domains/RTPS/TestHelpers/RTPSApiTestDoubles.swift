import Foundation

@testable import BreadPartners

actor RecaptchaStub: RecaptchaProviding {
    private let result: Result<String, NSError>
    private(set) var callCount = 0
    private(set) var lastSiteKey: String?
    private(set) var lastAction: String?
    private(set) var lastTimeout: Double?
    private(set) var lastDebug: Bool?

    init(result: Result<String, NSError> = .success("test-token")) {
        self.result = result
    }

    func execute(siteKey: String, action: String, timeout: Double, debug: Bool) async throws -> String {
        callCount += 1
        lastSiteKey = siteKey
        lastAction = action
        lastTimeout = timeout
        lastDebug = debug

        switch result {
        case let .success(token): return token
        case let .failure(error): throw error
        }
    }
}

actor HTTPClientSpy: HTTPClient {
    enum Outcome: Sendable {
        case success(Data)
        case failure(NSError)
    }

    private var outcomes: [Outcome]
    private(set) var requests: [HTTPRequest] = []

    var requestCount: Int {
        requests.count
    }

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func request(_ request: HTTPRequest) async throws -> Data {
        requests.append(request)
        let outcome = outcomes.isEmpty ? .success(Data()) : outcomes.removeFirst()

        switch outcome {
        case let .success(data):
            return data
        case let .failure(error):
            throw error
        }
    }
}

final class ResponseDecoderStub: RTPSResponseDecoding, @unchecked Sendable {
    enum Response {
        case rtps(RTPSResponse)
        case placements(PlacementsResponse)
    }

    private let lock = NSLock()
    private var responses: [Response]

    init(responses: [Response]) {
        self.responses = responses
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        lock.lock()
        defer { lock.unlock() }

        guard !responses.isEmpty else {
            throw NSError(
                domain: "ResponseDecoderStub",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No response configured"]
            )
        }

        let response = responses.removeFirst()
        switch response {
        case let .rtps(value):
            guard let value = value as? T else {
                throw NSError(
                    domain: "ResponseDecoderStub",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected response type"]
                )
            }
            return value
        case let .placements(value):
            guard let value = value as? T else {
                throw NSError(
                    domain: "ResponseDecoderStub",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected response type"]
                )
            }
            return value
        }
    }
}

final class EventCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedEvents: [BreadPartnerEvents] = []

    var first: BreadPartnerEvents? {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.first
    }

    var containsSDKError: Bool {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.contains { event in
            if case .sdkError = event { return true }
            return false
        }

    }

    var eventCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recordedEvents.count
    }

    func record(_ event: BreadPartnerEvents) {
        lock.lock()
        recordedEvents.append(event)
        lock.unlock()
    }
}

enum RTPSApiFixtures {
    enum URLs {
        static let prescreen = URL(string: "https://rtps.test/api/prescreen")!
        static let virtualLookup = URL(string: "https://rtps.test/api/virtual_lookup")!
    }

    enum MerchantConfigurationFixture {
        static let complete = MerchantConfiguration(
            buyer: BreadPartnersBuyer(
                givenName: "Ada",
                familyName: "Lovelace",
                billingAddress: BreadPartnersAddress(
                    address1: "1 Main Street",
                    country: "US",
                    locality: "Columbus",
                    region: "OH",
                    postalCode: "43004"
                )
            ),
            env: .stage
        )
    }

    enum PlacementConfigurationFixture {
        static let rtps = PlacementConfiguration(rtpsData: RTPSData())
    }

    enum Response {
        static let approved = RTPSResponse(
            returnCode: "01",
            prescreenId: 9001,
            cardType: "storeCard"
        )

        static let neutral = RTPSResponse()

        static let emptyPlacements = PlacementsResponse(
            placements: [],
            placementContent: nil
        )
    }

    enum Error {
        static let incapsula = NSError(
            domain: "IncapsulaChallenge",
            code: 0,
            userInfo: [
                "htmlContent": "<html>challenge</html>",
                "url": "https://challenge.test",
            ]
        )
    }
}
