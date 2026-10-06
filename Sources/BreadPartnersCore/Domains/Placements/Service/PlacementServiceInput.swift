import Foundation

package struct PlacementServiceInput: Sendable {
    package let httpClient: any HTTPClient
    package let request: PlacementRequest
    package let url: URL
    package let cookies: String?

    package init(
        httpClient: any HTTPClient,
        request: PlacementRequest,
        url: URL,
        cookies: String? = nil
    ) {
        self.httpClient = httpClient
        self.request = request
        self.url = url
        self.cookies = cookies
    }
}
