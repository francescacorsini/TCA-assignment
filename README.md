# TCA-assignment

Assignment about small iOS app using The Composable Architecture.

A small iOS app built with **SwiftUI** and **The Composable Architecture (TCA)**.
It has up to three screens on top of a public REST API.

> **Status:** project skeleton. The TCA structure (features, navigation, dependency client) is in
> place with empty placeholders. The public API, the screen content and the tests will be added
> in later commits.

---

## Requirements

| Tool / Setting | Version |
| --- | --- |
| Xcode | Latest stable (built with Xcode 27.2) |
| Swift | 6.x toolchain, Swift 5 language mode |
| Minimum deployment target | iOS 17.0 |
| Platforms | iPhone, iPad |

## How to build and run

1. Clone the repository.
2. Open `MyApp.xcodeproj` in Xcode.
3. Wait for Swift Package Manager to resolve the dependencies.
4. The first time, Xcode asks you to **Trust & Enable** the TCA macros. Accept, because TCA and its
   companion libraries rely on Swift macros (`@Reducer`, `@ObservableState`, `@DependencyClient`, …).
5. Select the `MyApp` scheme and an iOS 17+ simulator, then press **⌘R**.

No API key or other setup is required.

From the command line:

```sh
xcodebuild -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=iOS Simulator' \
  -skipMacroValidation build
```

## Architecture

The app follows **The Composable Architecture 1.x** with its current APIs:

- `@Reducer` for every feature,
- `@ObservableState` for feature state, observed directly by SwiftUI views,
- `StackState` / `StackAction` for push navigation,
- `@DependencyClient` for the API client.

Each screen is its own feature: a reducer and a view. Features are composed into a single root
feature.

### Project structure

```
MyApp/
├── App/
│   ├── MyApp.swift            // @main entry point, creates the root Store
│   ├── AppFeature.swift       // Root reducer: composes features, owns the navigation stack
│   └── AppView.swift          // NavigationStack bound to AppFeature.State.path
├── Features/
│   ├── ItemList/
│   │   ├── ItemListFeature.swift   // List screen reducer (loading / empty / error states)
│   │   └── ItemListView.swift      // List screen view
│   └── ItemDetail/
│       ├── ItemDetailFeature.swift // Detail screen reducer
│       └── ItemDetailView.swift    // Detail screen view
├── Dependencies/
│   └── APIClient/
│       └── APIClient.swift    // The client used by features to talk to the remote API
└── Assets.xcassets
```

### Feature tree and state flow

```
AppFeature
├── list: ItemListFeature              (root of the NavigationStack, always present)
└── path: StackState<AppFeature.Path>
    └── .detail(ItemDetailFeature)     (pushed when an item is selected)
```

- **One store, one source of truth.** `MyApp` creates a single `Store<AppFeature>`. Child views
  receive scoped stores (`store.scope(state:action:)`), so every screen only sees its own state
  and actions.
- **Downward flow.** `AppFeature.State` owns `ItemListFeature.State` directly and the pushed
  screens through `StackState<Path.State>`. Views observe state through `@ObservableState`.
- **Upward flow.** Views send actions to their own feature. Child actions are embedded in the
  parent's `Action` (`.list(...)`, `.path(...)`). The parent reduces them after the child, so it
  can react to them. For example, it pushes `.detail` onto `path` when the list reports a
  selection.
- **Navigation is state.** Pushing or popping a screen means appending or removing an element of
  `path`. `AppView` binds `NavigationStack(path:)` to that state, and `.forEach(\.path, action:
  \.path)` runs the reducer of each pushed screen.
- **Side effects go through dependencies.** Reducers never call `URLSession` directly. They will use
  `@Dependency(\.apiClient).`

## Third-party dependencies

| Package | Why |
| --- | --- |
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) (≥ 1.25.0, < 2.0.0) | Required by the assignment. |

No other third-party dependencies are used. Networking will use `URLSession`.

## Decisions and trade-offs

- **SwiftUI only.** No UIKit.
- **iOS 17 minimum.** This lets the views use Observation through `@ObservableState` (backported by
  TCA where needed) and `@Bindable` for navigation bindings.
- **Default actor isolation is `nonisolated`.** Xcode's new-project default of
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` infers MainActor-isolated conformances for the
  `@Reducer` types. That produces a `circular reference` error while the compiler resolves
  `ReducerOf<Self>`. With the classic `nonisolated` default, SwiftUI views stay on the main actor
  through `View`, and the TCA `Store` is `@MainActor` itself.
- **Stack-based navigation (`StackState`)** instead of tree-based (`@Presents`). A list → detail
  flow is a natural push, and the stack scales if more screens are added.
- **Placeholder reducers use `EmptyReducer()`** while their `Action` enums have no cases.

_To be completed as the app takes shape: chosen API and endpoints, the extra interaction,
error-handling and cancellation strategy, and what I would do with more time._

## Tests

Not added yet. When they are, they will use **Swift Testing** and TCA's `TestStore`.

## Use of AI tools

Claude (in Xcode) helped me deciding the initial TCA project structure, added the documentation comments
and this README. Then the rest of the codebase was added by the author and reviewed by Claude.
