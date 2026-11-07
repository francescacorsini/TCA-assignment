import ComposableArchitecture
import SwiftUI

/// The view for the list screen.
///
/// Renders the state of ``ItemListFeature`` and forwards user interactions
/// back to the store as actions.
///
// TODO: Add real content.
struct ItemListView: View {
    /// The store driving the list screen.
    let store: StoreOf<ItemListFeature>

    var body: some View {
        Text("Item List")
            .navigationTitle("Items")
    }
}

#Preview {
    NavigationStack {
        ItemListView(
            store: Store(initialState: ItemListFeature.State()) {
                ItemListFeature()
            }
        )
    }
}
