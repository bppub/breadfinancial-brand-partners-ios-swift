import BreadPartnersCore
import Foundation

internal final class LiveHTTPClient: HTTPClient, @unchecked Sendable {
    private let logger: Logger
    private let session: URLSession

    init(
        logger: Logger,
        session: URLSession = .shared
    ) {
        self.logger = logger
        self.session = session
    }

    package func request(_ request: HTTPRequest) async throws -> Data {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let userAgent = await DeviceInformationProvider.userAgent
        let genericHeaders: [String: String] = [
            Constants.headerContentType: Constants.headerContentTypeValue,
            Constants.headerUserAgentKey: userAgent,
            Constants.headerOriginKey: Constants.headerOriginValue,
            Constants.headerPlatformKey: Constants.headerPlatformValue,
        ]

        var updatedHeaders = request.headers.merging(
            genericHeaders,
            uniquingKeysWith: { first, _ in first }
        )

        if let cookies = request.cookies {
            updatedHeaders["Cookie"] = cookies
        }

        for (key, value) in updatedHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        urlRequest.httpBody = request.body

        logger.logRequestDetails(
            url: request.url,
            method: request.method.rawValue,
            headers: updatedHeaders,
            body: urlRequest.httpBody
        )

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "InvalidResponse", code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response from server."
                ])
        }

        logger.logResponseDetails(
            url: request.url,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields,
            body: data
        )

        guard (200...299).contains(httpResponse.statusCode) else {
            let messageString: String = {
                if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                    let message = (jsonObject as? [String: Any])?["message"] as? String
                {
                    return message
                }
                return String(data: data, encoding: .utf8) ?? "Message is blank"
            }()

            throw NSError(
                domain: "HTTPError", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: messageString]
            )
        }

        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard contentType.contains("application/json") else {
            let responseString =
                String(data: data, encoding: .utf8)
                ?? "Unable to decode response"

            if responseString.contains("_Incapsula_Resource")
                || responseString.contains("incap_ses")
            {
                throw NSError(
                    domain: "IncapsulaChallenge",
                    code: 403,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Security challenge detected. User interaction required.",
                        "htmlContent": responseString,
                        "url": request.url.absoluteString,
                    ]
                )
            }

            throw NSError(
                domain: "InvalidContentType",
                code: 415,
                userInfo: [
                    NSLocalizedDescriptionKey: "Server returned \(contentType) instead of JSON.",
                    "responseBody": responseString,
                ]
            )
        }

        return data
    }
}
