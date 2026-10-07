//------------------------------------------------------------------------------
//  File:          HTTPClientSpyTests.swift
//  Author(s):     Bread Financial
//  Date:          31 October 2026
//
//  Descriptions:  This file is part of the BreadPartners SDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import BreadPartnersCore
import BreadPartnersTestSupport
import Foundation
import Testing

@Suite
struct HTTPClientSpyTests {
    @Test(arguments: [HTTPMethod.GET, .POST, .PUT, .DELETE, .OPTIONS])
    func unexpectedRequestDescriptionIncludesMethodAndCompleteURL(method: HTTPMethod) throws {
        let url = try #require(URL(string: "https://api.test/unexpected?reason=empty%20queue#details"))
        let error = HTTPClientSpy.Failure.unexpectedRequest(method: method, url: url)
        let expectedDescription =
            "HTTPClientSpy received an unexpected \(method.rawValue) request to https://api.test/unexpected?reason=empty%20queue#details: no outcomes remain."

        #expect(error.errorDescription == expectedDescription)
        #expect(error.localizedDescription == expectedDescription)
        #expect((error as NSError).localizedDescription == expectedDescription)
    }

    @Test
    func defaultsToEmptyQueueAndRecordsUnexpectedRequest() async throws {
        let httpClient = HTTPClientSpy()
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/default")),
            method: .GET
        )

        #expect(await httpClient.requests.isEmpty)
        #expect(await httpClient.requestCount == 0)

        do {
            _ = try await httpClient.request(request)
            Issue.record("Expected an unexpected-request failure")
        } catch let error as HTTPClientSpy.Failure {
            #expect(error == .unexpectedRequest(method: request.method, url: request.url))
        }

        #expect(await httpClient.requestCount == 1)
        #expect(await httpClient.requests.first?.url == request.url)
    }

    @Test
    func returnsQueuedDataAndRecordsEachRequest() async throws {
        let firstData = Data("first".utf8)
        let secondData = Data("second".utf8)
        let httpClient = HTTPClientSpy(
            outcomes: [.success(firstData), .success(secondData)]
        )
        let firstRequest = HTTPRequest(
            url: try #require(URL(string: "https://api.test/first")),
            method: .POST,
            headers: ["X-Test": "value"],
            cookies: "session=value",
            body: Data("request".utf8)
        )
        let secondRequest = HTTPRequest(
            url: try #require(URL(string: "https://api.test/second")),
            method: .PUT
        )

        #expect(await httpClient.requests.isEmpty)
        #expect(try await httpClient.request(firstRequest) == firstData)
        #expect(try await httpClient.request(secondRequest) == secondData)
        #expect(await httpClient.requestCount == 2)
        let requests = await httpClient.requests
        #expect(requests.map(\.url) == [firstRequest.url, secondRequest.url])
        #expect(requests.map(\.method) == [.POST, .PUT])
        #expect(requests[0].headers == firstRequest.headers)
        #expect(requests[0].cookies == firstRequest.cookies)
        #expect(requests[0].body == firstRequest.body)
    }

    @Test
    func throwsQueuedFailureAfterRecordingRequestAndContinuesQueue() async throws {
        let expectedError = NSError(domain: "Network", code: 500)
        let responseData = Data("response".utf8)
        let httpClient = HTTPClientSpy(outcomes: [.failure(expectedError), .success(responseData)])
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/failure")),
            method: .POST
        )

        do {
            _ = try await httpClient.request(request)
            Issue.record("Expected the configured network failure")
        } catch {
            #expect(error as NSError === expectedError)
        }

        #expect(await httpClient.requestCount == 1)
        let recordedRequest = try #require(await httpClient.requests.first)
        #expect(recordedRequest.url == request.url)
        #expect(recordedRequest.method == request.method)
        #expect(try await httpClient.request(request) == responseData)
        #expect(await httpClient.requestCount == 2)
    }

    @Test(arguments: [true, false], [HTTPMethod.GET, .POST, .PUT, .DELETE, .OPTIONS])
    func exhaustedQueueThrowsAndRecordsUnexpectedRequest(initiallyEmpty: Bool, method: HTTPMethod) async throws {
        let responseData = Data("response".utf8)
        let httpClient = HTTPClientSpy(outcomes: initiallyEmpty ? [] : [.success(responseData)])
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/exhausted")),
            method: method
        )

        if !initiallyEmpty {
            #expect(try await httpClient.request(request) == responseData)
        }

        do {
            _ = try await httpClient.request(request)
            Issue.record("Expected an unexpected-request failure")
        } catch let error as HTTPClientSpy.Failure {
            #expect(error == .unexpectedRequest(method: request.method, url: request.url))
            #expect(
                error.localizedDescription
                    == "HTTPClientSpy received an unexpected \(method.rawValue) request to https://api.test/exhausted: no outcomes remain."
            )
        }

        #expect(await httpClient.requestCount == (initiallyEmpty ? 1 : 2))
        let recordedRequest = try #require(await httpClient.requests.last)
        #expect(recordedRequest.url == request.url)
        #expect(recordedRequest.method == request.method)
    }

    @Test
    func repeatedUnexpectedRequestsPreserveAllRecordedFields() async throws {
        let httpClient = HTTPClientSpy()
        let requests = [
            HTTPRequest(
                url: try #require(URL(string: "https://api.test/first")),
                method: .POST,
                headers: ["X-Test": "first"],
                cookies: "session=first",
                body: Data("first-body".utf8)
            ),
            HTTPRequest(
                url: try #require(URL(string: "https://api.test/second")),
                method: .PUT,
                headers: ["X-Test": "second"],
                cookies: "session=second",
                body: Data("second-body".utf8)
            ),
        ]

        for request in requests {
            do {
                _ = try await httpClient.request(request)
                Issue.record("Expected an unexpected-request failure")
            } catch let error as HTTPClientSpy.Failure {
                #expect(error == .unexpectedRequest(method: request.method, url: request.url))
            }
        }

        #expect(await httpClient.requestCount == requests.count)
        let recordedRequests = await httpClient.requests
        #expect(recordedRequests.map(\.url) == requests.map(\.url))
        #expect(recordedRequests.map(\.method) == requests.map(\.method))
        #expect(recordedRequests.map(\.headers) == requests.map(\.headers))
        #expect(recordedRequests.map(\.cookies) == requests.map(\.cookies))
        #expect(recordedRequests.map(\.body) == requests.map(\.body))
    }

    @Test
    func returnsEmptyDataWhenExplicitlyConfigured() async throws {
        let httpClient = HTTPClientSpy(outcomes: [.success(Data())])
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/empty-data")),
            method: .GET
        )

        #expect(try await httpClient.request(request) == Data())
        #expect(await httpClient.requestCount == 1)
    }

    @Test
    func throwsEachExplicitlyQueuedFailure() async throws {
        let expectedError = NSError(domain: "Network", code: 500)
        let httpClient = HTTPClientSpy(outcomes: [.failure(expectedError), .failure(expectedError)])
        let request = HTTPRequest(
            url: try #require(URL(string: "https://api.test/repeated-failure")),
            method: .GET
        )

        for _ in 0..<2 {
            do {
                _ = try await httpClient.request(request)
                Issue.record("Expected the configured network failure")
            } catch {
                #expect(error as NSError === expectedError)
            }
        }
        #expect(await httpClient.requestCount == 2)
        let recordedRequests = await httpClient.requests
        #expect(recordedRequests.allSatisfy { $0.url == request.url && $0.method == request.method })
    }
}
