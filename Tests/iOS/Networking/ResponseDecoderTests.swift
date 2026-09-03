import Foundation
import Testing
@testable import BreadPartners

@Suite struct ResponseDecoderTests {
    private struct TestValue: Decodable, Equatable {
        let id: Int
    }

    @Test
    func unwrapsAnySendableBeforeDecoding() throws {
        let value = try ResponseDecoder.decode(
            AnySendable(value: Data(#"{"id":42}"#.utf8)),
            as: TestValue.self
        )

        #expect(value == TestValue(id: 42))
    }

    @Test
    func rejectsUnsupportedWrappedPayload() {
        do {
            let _: TestValue = try ResponseDecoder.decode(
                AnySendable(value: "not-json"),
                as: TestValue.self
            )
            Issue.record("Expected unsupported wrapped payload to throw")
        } catch let error as NSError {
            #expect(error.domain == "JSONDecodingError")
            #expect(error.code == 1)
        }
    }
}
