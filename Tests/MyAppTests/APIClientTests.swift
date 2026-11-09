import Foundation
import Testing
@testable import MyApp

/// Verifies how the live `APIClient` maps transport, HTTP and decoding failures to `APIClientError`.
///
/// Requests are intercepted by ``StubURLProtocol``, so no real network traffic is made.
/// The suite is serialized because the stub is global state shared by `URLSession.shared`.
@Suite(.serialized)
final class APIClientTests {
    init() {
        URLProtocol.registerClass(StubURLProtocol.self)
    }

    deinit {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.result = nil
        StubURLProtocol.lastRequest = nil
    }

    @Test
    func plusSignInQueryIsPercentEncoded() async throws {
        StubURLProtocol.result = .success((statusCode: 200, body: Data(#"{"count":0,"offset":0,"artists":[]}"#.utf8)))

        _ = try await APIClient.liveValue.searchArtists("Bob + Earl")

        let query = try #require(StubURLProtocol.lastRequest?.url?.query(percentEncoded: true))
        #expect(query.contains("artist:Bob%20%2B%20Earl"))
    }

    @Test
    func noConnectionThrowsOffline() async {
        StubURLProtocol.result = .failure(URLError(.notConnectedToInternet))

        await #expect(throws: APIClientError.offline) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
    }

    @Test
    func cancelledRequestThrowsCancellationError() async {
        StubURLProtocol.result = .failure(URLError(.cancelled))

        await #expect(throws: CancellationError.self) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
    }

    @Test
    func otherURLErrorsArePassedThrough() async {
        StubURLProtocol.result = .failure(URLError(.timedOut))

        let error = await #expect(throws: URLError.self) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
        #expect(error?.code == .timedOut)
    }

    @Test
    func status503ThrowsRateLimited() async {
        StubURLProtocol.result = .success((statusCode: 503, body: Data()))

        await #expect(throws: APIClientError.rateLimited) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
    }

    @Test
    func otherErrorStatusThrowsHTTPStatusCode() async {
        StubURLProtocol.result = .success((statusCode: 500, body: Data()))

        await #expect(throws: APIClientError.httpStatusCode(500)) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
    }

    @Test
    func malformedSearchResponseThrowsDecoding() async {
        StubURLProtocol.result = .success((statusCode: 200, body: Data(#"{"unexpected": true}"#.utf8)))

        await #expect(throws: APIClientError.decoding) {
            try await APIClient.liveValue.searchArtists("Radiohead")
        }
    }

    @Test
    func malformedArtistResponseThrowsDecoding() async {
        StubURLProtocol.result = .success((statusCode: 200, body: Data("not json".utf8)))

        await #expect(throws: APIClientError.decoding) {
            try await APIClient.liveValue.fetchArtist("a74b1b7f-71a5-4011-9441-d0b5e4122711")
        }
    }
}

/// Intercepts MusicBrainz requests and answers them with ``result``.
private final class StubURLProtocol: URLProtocol {
    /// The canned outcome for the next intercepted request.
    nonisolated(unsafe) static var result: Result<(statusCode: Int, body: Data), URLError>?
    /// The most recent request the stub intercepted, so tests can inspect what was sent.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "musicbrainz.org"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request
        switch Self.result {
        case let .success((statusCode, body)):
            guard
                let url = request.url,
                let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)

        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)

        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
        }
    }

    override func stopLoading() {}
}
