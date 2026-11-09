import ComposableArchitecture
import Foundation

/// Loads and stores artist search results for the list screen.
@Reducer
struct ItemListFeature {
    @ObservableState
    struct State: Equatable {
        /// The text currently entered in the artist search field.
        var query = ""
        /// The artists returned by the most recent successful search.
        var artists: [Artist] = []
        /// The current phase of the search flow, used to select the screen's content state.
        var status: Status = .idle

        /// The mutually exclusive states of the artist search flow.
        enum Status: Equatable {
            /// Nothing searched yet: show a prompt.
            case idle
            /// First page of a new search is in flight.
            case loading
            /// A search completed successfully; results may be empty.
            case loaded
            /// The search failed and includes a message suitable for display.
            case failed(message: String)
        }
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
        case searchResponse(TaskResult<ArtistSearchResponse>)
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
                state.artists = []
                state.status = .idle
                return .cancel(id: CancelID.search)

            case .searchButtonTapped, .retryButtonTapped:
                let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                // Ignore writes that don't change what we'd search for: the same text, or
                // only leading/trailing whitespace.
                guard !query.isEmpty else {
                    state.status = .failed(message: "Enter an artist name to search.")
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
                state.artists = response.artists
                state.status = .loaded
                return .none

            case let .searchResponse(.failure(error)):
                state.artists = []
                state.status = .failed(message: error.localizedDescription)
                return .none
            }
        }
    }
}
