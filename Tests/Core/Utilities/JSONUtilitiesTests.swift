import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct JSONUtilitiesTests {
    private struct TestValue: Codable, Equatable {
        let id: Int
        let name: String
    }

    @Test
    func decodesData() throws {
        let value = try decodeJSON(
            from: Data(#"{"id":1,"name":"data"}"#.utf8),
            to: TestValue.self
        )

        #expect(value == TestValue(id: 1, name: "data"))
    }

    @Test
    func decodesDictionary() throws {
        let value = try decodeJSON(
            from: ["id": 2, "name": "dictionary"] as [String: Any],
            to: TestValue.self
        )

        #expect(value == TestValue(id: 2, name: "dictionary"))
    }

    @Test
    func decodesArray() throws {
        let values = try decodeJSON(
            from: [["id": 3, "name": "array"]] as [[String: Any]],
            to: [TestValue].self
        )

        #expect(values == [TestValue(id: 3, name: "array")])
    }

    @Test
    func rejectsUnsupportedPayload() {
        do {
            let _: TestValue = try decodeJSON(from: "not-json", to: TestValue.self)
            Issue.record("Expected unsupported payload to throw")
        } catch let error as NSError {
            #expect(error.domain == "JSONDecodingError")
            #expect(error.code == 1)
            #expect(error.localizedDescription == "Unsupported JSON structure")
        }
    }

    @Test
    func removesNilValuesAndNormalizesNestedDoubles() throws {
        let input: [String: Any?] = [
            "missing": nil,
            "amount": 1.236,
            "nested": ["amount": 9.999, "missing": nil] as [String: Any?],
        ]
        let output = try #require(unwrapForJSON(input) as? [String: Any])
        let nested = try #require(output["nested"] as? [String: Any])

        #expect(output["missing"] == nil)
        #expect(output["amount"] as? Double == 1.24)
        #expect(nested["missing"] == nil)
        #expect(nested["amount"] as? Double == 10.0)
    }

    @Test
    func stringifiesJSONWithSortedKeys() {
        let input: [String: Any?] = ["z": 1, "a": "first", "missing": nil]

        #expect(stringifyJSON(input) == "{\n  \"a\" : \"first\",\n  \"z\" : 1\n}")
    }

    @Test
    func stringifyJSONReturnsEmptyStringForUnsupportedValue() {
        #expect(stringifyJSON(["invalid": Double.nan]) == "")
    }
}
