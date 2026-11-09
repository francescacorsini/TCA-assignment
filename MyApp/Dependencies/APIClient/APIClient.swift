import ComposableArchitecture
import Foundation

/// Spaces MusicBrainz requests by at least one second, including concurrent searches.
/// MusicBrainz applies an average limit of one request per second per client IP.
private actor MusicBrainzRateLimiter {
    /// One shared limiter ensures all searches in the app follow the same schedule.
    static let shared = MusicBrainzRateLimiter()

    private let clock = ContinuousClock()
    private var lastRequestTime: ContinuousClock.Instant?

    /// Suspends until a request slot is available; cancellation interrupts the wait.
    func waitForNextRequest() async throws {
        while let lastRequestTime {
            let nextAllowedTime = lastRequestTime.advanced(by: .seconds(1))
            if clock.now >= nextAllowedTime { break }
            try await clock.sleep(until: nextAllowedTime)
        }
        lastRequestTime = clock.now
    }
}

/// The client used by features to talk to the MusicBrainz Web Service.
@DependencyClient
struct APIClient {
    /// Searches MusicBrainz for artists matching the supplied name or query.
    var searchArtists: @Sendable (_ query: String) async throws -> ArtistSearchResponse
}

extension APIClient: DependencyKey {
    static let liveValue = Self(
        searchArtists: { query in
            try await MusicBrainzRateLimiter.shared.waitForNextRequest()

            // This fixed endpoint is a valid URL literal, so URLComponents creation cannot fail.
            var components = URLComponents(string: "https://musicbrainz.org/ws/2/artist/")!
            components.queryItems = [
                URLQueryItem(name: "query", value: "artist:\(query)"),
                URLQueryItem(name: "fmt", value: "json"),
                URLQueryItem(name: "limit", value: "25")
            ]

            guard let url = components.url else {
                throw APIClientError.genericError("Failed to create URL request.")
            }
                    
            var request = URLRequest(url: url)
            // MusicBrainz requires an identifiable User-Agent so its maintainers can contact
            // the app owner if the client causes problems or needs to be throttled.
            request.setValue(
                "TCAAssignment/1.0 (https://github.com/francescacorsini/TCA-assignment)",
                forHTTPHeaderField: "User-Agent"
            )

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw APIClientError.invalidResponse
            }
            guard (200..<300).contains(response.statusCode) else {
                throw APIClientError.httpStatusCode(response.statusCode)
            }

            return try JSONDecoder().decode(ArtistSearchResponse.self, from: data)
        }
    )
}

extension DependencyValues {
    /// The MusicBrainz API client used by feature reducers.
    var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

/// Errors produced when MusicBrainz returns an unusable HTTP response.
enum APIClientError: Error, Equatable, LocalizedError, Sendable {
    /// The URL loading system returned a response that was not HTTP.
    case invalidResponse
    /// MusicBrainz returned an HTTP status outside the successful 2xx range.
    case httpStatusCode(Int)
    /// A generic error with a readable description, used for testing and previews.
    case genericError(String)

    /// A readable explanation for the failed request.
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server returned an invalid response."
        case let .httpStatusCode(code):
            "MusicBrainz returned HTTP \(code). Please try again."
        case .genericError(_):
            "An error occurred while processing the request. Please try again."
        }
    }
}
