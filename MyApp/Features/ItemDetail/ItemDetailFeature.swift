import ComposableArchitecture
import Foundation

/// Loads the selected artist's full MusicBrainz record and release groups.
@Reducer
struct ItemDetailFeature {
    @ObservableState
    struct State: Equatable {
        /// The artist selected from the search results; shown until the full lookup arrives.
        var artist: Artist
        /// The artist lookup; `.loaded` carries the full record including release groups.
        var status: LoadingState<Artist> = .idle

        /// The richest artist data available: the full lookup once loaded, otherwise the search result.
        var displayedArtist: Artist { status.value ?? artist }
    }

    /// User intents and asynchronous lookup results handled by the detail feature.
    enum Action {
        /// Loads the selected artist's full MusicBrainz record.
        case loadArtist
        /// Retries the lookup after a failure.
        case retryButtonTapped
        /// Delivers the result of an artist lookup request.
        case artistResponse(Result<Artist, any Error>)
    }

    @Dependency(\.apiClient) private var apiClient

    /// Identifies the in-flight lookup so it can be cancelled if the detail feature is removed.
    private enum CancelID {
        /// Cancellation identifier for this artist lookup.
        case artistLookup
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadArtist:
                guard state.status == .idle else { return .none }
                return fetchArtist(&state)

            case .retryButtonTapped:
                guard case .failed = state.status else { return .none }
                return fetchArtist(&state)

            case let .artistResponse(.success(artist)):
                state.status = .loaded(artist)
                return .none

            case let .artistResponse(.failure(error)):
                state.status = .failed(message: error.localizedDescription)
                return .none
            }
        }
    }

    /// Marks the lookup as loading and starts fetching the artist's full record.
    /// A newer lookup cancels any request still in flight.
    private func fetchArtist(_ state: inout State) -> Effect<Action> {
        state.status = .loading
        let artistID = state.artist.id

        return .run { [artistID] send in
            do {
                let artist = try await apiClient.fetchArtist(artistID)
                await send(.artistResponse(.success(artist)))
            } catch {
                await send(.artistResponse(.failure(error)))
            }
        }
        .cancellable(id: CancelID.artistLookup, cancelInFlight: true)
    }
}
