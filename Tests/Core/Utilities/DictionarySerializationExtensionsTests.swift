import Foundation
import Testing
@testable import BreadPartnersCore

@Suite struct DictionarySerializationExtensionsTests {
    private struct UnsupportedQueryValue: CustomStringConvertible {
        var description: String { "custom value" }
    }

    @Test
    func assignDefinedIncludesOnlyDefinedAndNonemptyValues() {
        var values: [String: Any?] = ["existing": "kept"]

        values.assignDefined([
            "string": "value",
            "empty": "",
            "missing": nil,
            "number": 5,
            "boolean": true,
        ])

        #expect(values["existing"] as? String == "kept")
        #expect(values["string"] as? String == "value")
        #expect(values["empty"] == nil)
        #expect(values["missing"] == nil)
        #expect(values["number"] as? Int == 5)
        #expect(values["boolean"] as? Bool == true)
    }

    @Test
    func queryStringSerializesSupportedValues() throws {
        let values: [String: Any?] = [
            "string": "value",
            "boolean": true,
            "double": 1.2,
            "number": 5,
            "missing": nil,
        ]
        let components = try #require(
            URLComponents(string: "https://example.com?\(values.toQueryString())")
        )
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) }
        )

        #expect(query["string"] == "value")
        #expect(query["boolean"] == "true")
        #expect(query["double"] == "1.20")
        #expect(query["number"] == "5")
        #expect(query["missing"] == nil)
    }

    @Test
    func queryStringSerializesNestedJSONValues() throws {
        let values: [String: Any?] = [
            "object": ["amount": 1.236] as [String: Any?],
            "array": [1, "two"],
        ]
        let components = try #require(
            URLComponents(string: "https://example.com?\(values.toQueryString())")
        )
        let query = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )
        let objectData = try #require(query["object"]?.data(using: .utf8))
        let arrayData = try #require(query["array"]?.data(using: .utf8))
        let object = try #require(
            JSONSerialization.jsonObject(with: objectData) as? [String: Double]
        )
        let array = try #require(JSONSerialization.jsonObject(with: arrayData) as? [Any])

        #expect(object["amount"] == 1.24)
        #expect(array[0] as? Int == 1)
        #expect(array[1] as? String == "two")
    }

    @Test
    func queryStringDescribesUnsupportedValue() {
        let values: [String: Any?] = ["custom": UnsupportedQueryValue()]

        #expect(values.toQueryString() == "custom=custom%20value")
    }
}
