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
    func blankQueryStaysIdleWithoutCallingAPI() async {
        let store = TestStore(initialState: ItemListFeature.State(query: "   ")) {
            ItemListFeature()
        } withDependencies: {
            $0.apiClient.searchArtists = { _ in
                Issue.record("A blank query must not call the API.")
                return Mocks.artistSearchResponse
            }
        }

        // No state change: the screen stays on the idle prompt.
        await store.send(.searchButtonTapped)
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
