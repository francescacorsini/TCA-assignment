import ComposableArchitecture
import SwiftUI

/// The application entry point.
///
/// It owns the single root `Store` for the whole app and hands it to ``AppView``.
/// The store is created once, for the lifetime of the process, so that all
/// feature state lives in one place and flows down through scoping.
@main
struct MyApp: App {
    /// The root store driving ``AppFeature``.
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
