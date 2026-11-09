import ComposableArchitecture
import Testing
@testable import MyApp

@MainActor
struct AppFeatureTests {
    @Test
    func selectingArtistPushesDetailDestination() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.list(.delegate(.artistSelected(Mocks.artist)))) {
            $0.path.append(.detail(ItemDetailFeature.State(artist: Mocks.artist)))
        }
    }
}
