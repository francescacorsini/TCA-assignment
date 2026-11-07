import ComposableArchitecture
import SwiftUI

/// The view for the detail screen.
///
/// Renders the state of ``ItemDetailFeature`` and forwards user interactions
/// back to the store as actions.
///
// TODO: Add real content.
struct ItemDetailView: View {
    /// The store driving the detail screen.
    let store: StoreOf<ItemDetailFeature>

    var body: some View {
        Text("Item Detail")
            .navigationTitle("Detail")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(
            store: Store(initialState: ItemDetailFeature.State()) {
                ItemDetailFeature()
            }
        )
    }
}
