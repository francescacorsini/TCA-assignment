import ComposableArchitecture
import Testing
@testable import MyApp

@MainActor
struct ItemListFeatureTests {
    @Test
    func searchLoadsArtists() async {
        let store = TestStore(initialState: ItemListFeature.State(query: "Radiohead")) {
            ItemListFeature()
        } withDependencies: {
            $0.apiClient.searchArtists = { _ in Mocks.artistSearchResponse }
        }

        await store.send(.searchButtonTapped) {
            $0.status = .loading
        }
        await store.receive(\.searchResponse) {
            $0.status = .loaded(Mocks.artistSearchResponse)
        }
    }

    @Test
    func emptyQueryShowsValidationWithoutCallingAPI() async {
        let store = TestStore(initialState: ItemListFeature.State()) {
            ItemListFeature()
        } withDependencies: {
            $0.apiClient.searchArtists = { _ in Mocks.artistSearchResponse }
        }

        await store.send(.searchButtonTapped) {
            $0.status = .failed(message: "Enter an artist name to search.")
        }
    }

    @Test(arguments: [APIClientError.offline, .rateLimited, .decoding])
    func searchFailureShowsErrorMessage(error: APIClientError) async {
        let store = TestStore(initialState: ItemListFeature.State(query: "Radiohead")) {
            ItemListFeature()
        } withDependencies: {
            $0.apiClient.searchArtists = { _ in throw error }
        }

        await store.send(.searchButtonTapped) {
            $0.status = .loading
        }
        await store.receive(\.searchResponse) {
            $0.status = .failed(message: error.localizedDescription)
        }
    }
}
