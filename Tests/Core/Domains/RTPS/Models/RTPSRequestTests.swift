import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSRequestTests {
    @Test
    func defaultsPlatformAndStoreNumber() {
        let request = RTPSRequest()

        #expect(request.platform == "ios")
        #expect(request.storeNumber == "8883")
    }

    @Test
    func encodesPrescreenFields() throws {
        let request = RTPSRequest(
            firstName: "Ada",
            lastName: "Lovelace",
            reCaptchaToken: "token",
            overrideConfig: .init(enhancedPresentment: true)
        )
        let data = try JSONEncoder().encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["firstName"] as? String == "Ada")
        #expect(object["reCaptchaToken"] as? String == "token")
        #expect(object["platform"] as? String == "ios")
    }
}
