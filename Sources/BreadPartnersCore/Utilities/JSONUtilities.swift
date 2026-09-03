import Foundation

package func decodeJSON<T: Decodable>(from response: Any, to type: T.Type) throws -> T {
    let data: Data

    if let responseData = response as? Data {
        data = responseData
    } else if let responseDictionary = response as? [String: Any] {
        data = try JSONSerialization.data(withJSONObject: responseDictionary)
    } else if let responseArray = response as? [[String: Any]] {
        data = try JSONSerialization.data(withJSONObject: responseArray)
    } else {
        throw NSError(
            domain: "JSONDecodingError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unsupported JSON structure"]
        )
    }

    return try JSONDecoder().decode(T.self, from: data)
}

/// Converts an object to a deterministic JSON string.
public func stringifyJSON(_ object: Any) -> String {
    let unwrapped = unwrapForJSON(object)

    guard JSONSerialization.isValidJSONObject(unwrapped) else { return "" }

    let data = try? JSONSerialization.data(
        withJSONObject: unwrapped,
        options: [.prettyPrinted, .sortedKeys]
    )
    return String(decoding: data!, as: UTF8.self)
}

/// Recursively removes nil values and normalizes doubles for JSON serialization.
public func unwrapForJSON(_ value: Any) -> Any {
    if let dictionary = value as? [String: Any?] {
        var result: [String: Any] = [:]
        for (key, optionalValue) in dictionary {
            guard let optionalValue else { continue }

            let unwrapped = unwrapForJSON(optionalValue)
            if let doubleValue = unwrapped as? Double {
                result[key] = Double(String(format: "%.2f", doubleValue))!
            } else {
                result[key] = unwrapped
            }
        }
        return result
    } else if let array = value as? [Any] {
        return array.map { unwrapForJSON($0) }
    } else if let doubleValue = value as? Double {
        return Double(String(format: "%.2f", doubleValue))!
    }
    return value
}
