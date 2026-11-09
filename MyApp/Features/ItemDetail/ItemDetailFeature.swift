import ComposableArchitecture
import Foundation

/// Loads the selected artist's full MusicBrainz record and release groups.
@Reducer
struct ItemDetailFeature {
    @ObservableState
    struct State: Equatable {
        /// The artist selected from the search results, enriched after a successful lookup.
        var artist: Artist
        /// The loading state for the artist lookup and release groups.
        var status: Status = .idle

        /// The mutually exclusive states of the artist lookup.
        enum Status: Equatable {
            /// The lookup has not started yet.
            case idle
            /// MusicBrainz is loading the artist's full record.
            case loading
            /// The lookup completed successfully; release groups may be empty.
            case loaded
            /// The lookup failed and includes a message suitable for display.
            case failed(message: String)
        }
    }

    /// User intents and asynchronous lookup results handled by the detail feature.
    enum Action {
        /// Loads the selected artist's full MusicBrainz record.
        case loadArtist
        /// Retries the lookup after a failure.
        case retryButtonTapped
        /// Delivers the result of an artist lookup request.
        case artistResponse(TaskResult<Artist>)
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

            case .retryButtonTapped:
                guard case .failed = state.status else { return .none }
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

            case let .artistResponse(.success(artist)):
                state.artist = artist
                state.status = .loaded
                return .none

            case let .artistResponse(.failure(error)):
                state.status = .failed(message: error.localizedDescription)
                return .none
            }
        }
    }
}
