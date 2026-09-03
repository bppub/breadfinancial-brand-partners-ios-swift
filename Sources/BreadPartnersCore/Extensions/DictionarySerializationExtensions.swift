import Foundation

package extension Dictionary where Key == String, Value == Any? {
    func toQueryString() -> String {
        compactMap { key, value -> String? in
            guard let value else { return nil }

            let stringValue: String
            if let value = value as? String {
                stringValue = value
            } else if let value = value as? Bool {
                stringValue = value ? "true" : "false"
            } else if let value = value as? Double {
                stringValue = String(format: "%.2f", value)
            } else if let value = value as? NSNumber {
                stringValue = value.stringValue
            } else if let value = value as? [String: Any?],
                let data = try? JSONSerialization.data(withJSONObject: unwrapForJSON(value))
            {
                stringValue = String(decoding: data, as: UTF8.self)
            } else if let value = value as? [Any],
                let data = try? JSONSerialization.data(withJSONObject: unwrapForJSON(value))
            {
                stringValue = String(decoding: data, as: UTF8.self)
            } else {
                stringValue = String(describing: value)
            }

            let encodedValue = stringValue.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            )!
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")
    }

    @discardableResult
    mutating func assignDefined(_ sources: [String: Any?]...) -> [String: Any?] {
        for source in sources {
            for (key, value) in source {
                if let stringValue = value as? String {
                    if !stringValue.isEmpty {
                        self[key] = value
                    }
                } else if value != nil {
                    self[key] = value
                }
            }
        }
        return self
    }
}
