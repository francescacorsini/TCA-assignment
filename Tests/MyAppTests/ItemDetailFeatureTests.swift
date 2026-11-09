import ComposableArchitecture
import Testing
@testable import MyApp

@MainActor
struct ItemDetailFeatureTests {
    @Test
    func loadArtistUpdatesDetailState() async {
        let store = TestStore(initialState: ItemDetailFeature.State(artist: .mockRadiohead)) {
            ItemDetailFeature()
        } withDependencies: {
            $0.apiClient.fetchArtist = { _ in Mocks.artist }
        }

        await store.send(.loadArtist) {
            $0.status = .loading
        }
        await store.receive(\.artistResponse) {
            $0.status = .loaded(Mocks.artist)
        }
    }

    @Test(arguments: [APIClientError.offline, .rateLimited, .decoding])
    func loadArtistFailureShowsErrorMessage(error: APIClientError) async {
        let store = TestStore(initialState: ItemDetailFeature.State(artist: .mockRadiohead)) {
            ItemDetailFeature()
        } withDependencies: {
            $0.apiClient.fetchArtist = { _ in throw error }
        }

        await store.send(.loadArtist) {
            $0.status = .loading
        }
        await store.receive(\.artistResponse) {
            $0.status = .failed(message: error.localizedDescription)
        }
    }
}
