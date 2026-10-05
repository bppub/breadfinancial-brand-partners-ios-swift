import Foundation

package struct FoundationHTTPClient: HTTPClient {
    private let session: any HTTPDataLoading
    private let defaultHeaders: @Sendable () async -> [String: String]
    private let logRequest: @Sendable (HTTPRequest, [String: String]) -> Void
    private let logResponse: @Sendable (URL, HTTPURLResponse, Data) -> Void

    package init(
        session: any HTTPDataLoading = URLSession.shared,
        defaultHeaders: @escaping @Sendable () async -> [String: String] = { [:] },
        logRequest: @escaping @Sendable (HTTPRequest, [String: String]) -> Void = { _, _ in },
        logResponse: @escaping @Sendable (URL, HTTPURLResponse, Data) -> Void = { _, _, _ in }
    ) {
        self.session = session
        self.defaultHeaders = defaultHeaders
        self.logRequest = logRequest
        self.logResponse = logResponse
    }

    package func request(_ request: HTTPRequest) async throws -> Data {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var headers = request.headers.merging(
            await defaultHeaders(),
            uniquingKeysWith: { first, _ in first }
        )

        if let cookies = request.cookies {
            headers["Cookie"] = cookies
        }

        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        urlRequest.httpBody = request.body
        logRequest(request, headers)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "InvalidResponse", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response from server."]
            )
        }

        logResponse(request.url, httpResponse, data)

        guard (200...299).contains(httpResponse.statusCode) else {
            let message: String
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                let jsonMessage = (jsonObject as? [String: Any])?["message"] as? String
            {
                message = jsonMessage
            } else {
                message = String(data: data, encoding: .utf8) ?? "Message is blank"
            }

            throw NSError(
                domain: "HTTPError", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }

        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard contentType.contains("application/json") else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"

            if responseString.contains("_Incapsula_Resource") || responseString.contains("incap_ses") {
                throw NSError(
                    domain: NetworkChallengeConstants.domain,
                    code: 403,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Security challenge detected. User interaction required.",
                        NetworkChallengeConstants.htmlContentKey: responseString,
                        NetworkChallengeConstants.urlKey: request.url.absoluteString,
                    ]
                )
            }

            throw NSError(
                domain: "InvalidContentType", code: 415,
                userInfo: [
                    NSLocalizedDescriptionKey: "Server returned \(contentType) instead of JSON.",
                    "responseBody": responseString,
                ]
            )
        }

        return data
    }
}
