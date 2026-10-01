import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSResponseTests {
    @Test
    func initializesAllResponseProperties() {
        let response = RTPSResponse(
            returnCode: "01",
            prescreenId: 42,
            firstName: "Ada",
            middleInitial: "L",
            lastName: "Lovelace",
            address1: "1 Main St",
            address2: "Suite 2",
            city: "Columbus",
            state: "OH",
            zip: "43004",
            cardType: "storeCard",
            isExpired: false,
            hasExistingAccount: true,
            errorMessage: "message",
            errorCode: 7
        )

        #expect(response.returnCode == "01")
        #expect(response.prescreenId == 42)
        #expect(response.firstName == "Ada")
        #expect(response.middleInitial == "L")
        #expect(response.lastName == "Lovelace")
        #expect(response.address1 == "1 Main St")
        #expect(response.address2 == "Suite 2")
        #expect(response.city == "Columbus")
        #expect(response.state == "OH")
        #expect(response.zip == "43004")
        #expect(response.cardType == "storeCard")
        #expect(response.isExpired == false)
        #expect(response.hasExistingAccount == true)
        #expect(response.errorMessage == "message")
        #expect(response.errorCode == 7)
    }

    @Test
    func decodesStringReturnCodeAndInt64PrescreenId() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":"01","prescreenId":9876543210}"#.utf8)
        )

        #expect(response.returnCode == "01")
        #expect(response.prescreenId == 9_876_543_210)
    }

    @Test
    func decodesIntegerReturnCode() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":0}"#.utf8)
        )

        #expect(response.returnCode == "0")
    }

    @Test
    func setsReturnCodeToNilForUnsupportedType() throws {
        let response = try JSONDecoder().decode(
            RTPSResponse.self,
            from: Data(#"{"returnCode":true}"#.utf8)
        )

        #expect(response.returnCode == nil)
    }
}
