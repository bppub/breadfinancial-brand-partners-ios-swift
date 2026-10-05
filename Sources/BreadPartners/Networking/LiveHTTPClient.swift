import BreadPartnersCore
import Foundation

internal final class LiveHTTPClient: HTTPClient {
    private let client: FoundationHTTPClient

    init(
        logger: Logger,
        session: any HTTPDataLoading = URLSession.shared
    ) {
        self.client = FoundationHTTPClient(
            session: session,
            defaultHeaders: {
                let userAgent = await DeviceInformationProvider.userAgent
                return [
                    Constants.headerContentType: Constants.headerContentTypeValue,
                    Constants.headerUserAgentKey: userAgent,
                    Constants.headerOriginKey: Constants.headerOriginValue,
                    Constants.headerPlatformKey: Constants.headerPlatformValue,
                ]
            },
            logRequest: { request, headers in
                logger.logRequestDetails(
                    url: request.url,
                    method: request.method.rawValue,
                    headers: headers,
                    body: request.body
                )
            },
            logResponse: { url, response, data in
                logger.logResponseDetails(
                    url: url,
                    statusCode: response.statusCode,
                    headers: response.allHeaderFields,
                    body: data
                )
            }
        )
    }

    package func request(_ request: HTTPRequest) async throws -> Data {
        try await client.request(request)
    }
}
