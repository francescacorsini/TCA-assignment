import ComposableArchitecture
import SwiftUI

/// The root view of the application.
///
/// Hosts a `NavigationStack` driven by ``AppFeature/State/path``.
/// The list screen is the stack's root, and every pushed destination is
/// resolved from ``AppFeature/Path``.
struct AppView: View {
    /// The store driving the root feature. 
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ItemListView(store: store.scope(state: \.list, action: \.list))
        } destination: { store in
            switch store.case {
            case let .detail(detailStore):
                ItemDetailView(store: detailStore)
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
