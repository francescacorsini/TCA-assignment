import ComposableArchitecture

/// The detail screen feature.
///
/// Pushed from the list screen through ``AppFeature/Path``. It shows more
/// information about the selected item and, where the API allows it, loads
/// additional data on appearance.
///
// TODO: Add State, actions and effects.
@Reducer
struct ItemDetailFeature {
    /// The state of the detail screen.
    @ObservableState
    struct State: Equatable {}

    /// The actions the detail screen can receive, from the view or from effects.
    enum Action {}

    var body: some ReducerOf<Self> {
        // `Action` has no cases yet, so there is nothing to reduce.
        // TODO: Replace with a `Reduce` once actions are added.
        EmptyReducer()
    }
}
