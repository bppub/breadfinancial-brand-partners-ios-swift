import BreadPartnersCore
import Foundation
import Testing
@testable import BreadPartners

@Suite struct LiveRTPSResponseDecoderTests {
    private struct TestResponse: Decodable, Equatable {
        let id: Int
        let message: String
    }

    @Test
    func decodesResponseData() throws {
        let data = Data(#"{"id":42,"message":"approved"}"#.utf8)

        let value = try LiveRTPSResponseDecoder().decode(
            TestResponse.self,
            from: data
        )

        #expect(value == TestResponse(id: 42, message: "approved"))
    }

    @Test
    func propagatesDecodingErrors() {
        let data = Data(#"{"id":"not-an-int","message":"failed"}"#.utf8)

        #expect(throws: DecodingError.self) {
            try LiveRTPSResponseDecoder().decode(TestResponse.self, from: data)
        }
    }
}
