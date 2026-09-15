import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct RTPSResponseTests {
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
