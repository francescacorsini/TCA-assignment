/// The lifecycle of an asynchronous load, shared by every screen that fetches data.
///
/// The loaded value lives inside `.loaded`, so a screen can never show stale
/// results while it is loading or has failed.
enum LoadingState<Value> {
    /// Nothing has been requested yet.
    case idle
    /// A request is in flight.
    case loading
    /// The request succeeded with the given value.
    case loaded(Value)
    /// The request failed, with a message suitable for display.
    case failed(message: String)

    /// The loaded value, or `nil` in every other state.
    var value: Value? {
        guard case let .loaded(value) = self else { return nil }
        return value
    }
}

extension LoadingState: Equatable where Value: Equatable {}
