import ComposableArchitecture

/// The list screen feature.
///
/// Responsible for loading the collection of items from the API and exposing
/// its loading, empty and error states to ``ItemListView``.
///
// TODO: Add State, actions and effects
@Reducer
struct ItemListFeature {
    /// The state of the list screen.
    @ObservableState
    struct State: Equatable {}

    /// The actions the list screen can receive, from the view or from effects.
    enum Action {}

    var body: some ReducerOf<Self> {
        // `Action` has no cases yet, so there is nothing to reduce.
        // TODO: Replace with a `Reduce` once actions are added.
        EmptyReducer()
    }
}
