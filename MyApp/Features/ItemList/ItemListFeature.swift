import ComposableArchitecture
import Foundation

/// Loads and stores artist search results for the list screen.
@Reducer
struct ItemListFeature {
    @ObservableState
    struct State: Equatable {
        /// The text currently entered in the artist search field.
        var query = ""
        /// The current phase of the search; `.loaded` carries the latest search response.
        var status: LoadingState<ArtistSearchResponse> = .idle
    }

    /// User intents and asynchronous results handled by the list feature.
    enum Action {
        /// Updates the search field and invalidates results from a previous query.
        case queryChanged(String)
        /// Starts an artist search for the current query.
        case searchButtonTapped
        /// Retries the artist search after a failure.
        case retryButtonTapped
        /// Announces a user selection to the parent feature for navigation.
        case delegate(Delegate)
        /// Delivers the result of an artist search request.
        case searchResponse(Result<ArtistSearchResponse, any Error>)
    }

    /// Events the list feature delegates to its parent.
    enum Delegate {
        /// The user selected an artist to inspect.
        case artistSelected(Artist)
    }

    @Dependency(\.apiClient) private var apiClient

    /// Identifies the in-flight search effect so a newer search can cancel the previous one.
    private enum CancelID {
        /// Cancellation identifier for the artist search request.
        case search
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                state.status = .idle
                return .cancel(id: CancelID.search)

            case .searchButtonTapped, .retryButtonTapped:
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                // An empty or whitespace-only query is not a failure: stay on the idle prompt,
                // which already asks for an artist name, and don't call the API.
                guard !query.isEmpty else {
                    state.status = .idle
                    return .cancel(id: CancelID.search)
                }

                state.status = .loading

                return .run { [query] send in
                    do {
                        let response = try await apiClient.searchArtists(query)
                        await send(.searchResponse(.success(response)))
                    } catch {
                        await send(.searchResponse(.failure(error)))
                    }
                }
                .cancellable(id: CancelID.search, cancelInFlight: true)

            case .delegate:
                return .none

            case let .searchResponse(.success(response)):
                state.status = .loaded(response)
                return .none

            case let .searchResponse(.failure(error)):
                state.status = .failed(message: error.localizedDescription)
                return .none
            }
        }
    }
}
