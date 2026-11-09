# TCA-assignment

Assignment about small iOS app using The Composable Architecture.

A small iOS app built with **SwiftUI** and **The Composable Architecture (TCA)**.
It has up to three screens on top of the public MusicBrainz REST API.

> **Status:** MusicBrainz artist search and artist detail navigation are implemented through TCA
> dependencies. The detail screen loads release groups, with reducer tests written using Swift Testing.

---

## Requirements

| Tool / Setting | Version |
| --- | --- |
| Xcode | Latest stable (built with Xcode 27.2) |
| Swift | 6.x toolchain, Swift 6 language mode |
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
├── Models/
│   ├── Models.swift                // Codable models for MusicBrainz artist and release-group data
│   └── Mocks.swift                 // Shared static mock data used by SwiftUI previews
├── Dependencies/
│   └── APIClient/
│       └── APIClient.swift    // TCA live and mock-preview implementations for MusicBrainz
├── Tests/
│   └── MyAppTests/             // Swift Testing coverage for list, detail, and navigation reducers
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
  can react to them. The list delegates an artist selection to the parent, which pushes the
  selected artist's detail feature onto `path`.
- **Navigation is state.** Pushing or popping a screen means appending or removing an element of
  `path`. `AppView` binds `NavigationStack(path:)` to that state, and `.forEach(\.path, action:
  \.path)` runs the reducer of each pushed screen.
- **Side effects go through dependencies.** Reducers never call `URLSession` directly. The list
  searches artists and the detail feature loads an artist with release groups through
  `@Dependency(\.apiClient)`. The one deliberate exception is album cover thumbnails, which the
  view loads with `AsyncImage` (see [Decisions and trade-offs](#decisions-and-trade-offs)).

## API integration

The app uses the public [MusicBrainz Web Service](https://musicbrainz.org/doc/MusicBrainz_API), which requires no API key. Example requests:

- Search artists: `GET https://musicbrainz.org/ws/2/artist/?query=artist:radiohead&fmt=json&limit=25`
- Look up an artist and their release groups: `GET https://musicbrainz.org/ws/2/artist/{MBID}?inc=release-groups&fmt=json`

MusicBrainz asks clients to send a descriptive `User-Agent` and limits requests to an average of one per second per IP address. The API client sends an app name/version and repository URL in the header and spaces requests at least one second apart. Its community-maintained catalogue can contain incomplete or ambiguous metadata, and release groups are limited to 25 in a lookup response; the app treats optional fields as missing data.

Album covers come from the [Cover Art Archive](https://coverartarchive.org), MusicBrainz's companion image service, using the release-group MBID the lookup already returns:

- Front cover thumbnail: `GET https://coverartarchive.org/release-group/{MBID}/front-250`

The archive redirects to the image on archive.org, or answers `404` when a release group has no cover; the detail screen then shows a placeholder. These requests don't count toward the MusicBrainz rate limit. MusicBrainz has no artist images, so artists are shown without a picture.

## Third-party dependencies

| Package | Why |
| --- | --- |
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) (≥ 1.25.0, < 2.0.0) | Required by the assignment. |

No other third-party dependencies are used. Networking will use `URLSession`.

## Decisions and trade-offs

- **SwiftUI only.** No UIKit.
- **iOS 17 minimum.** This lets the views use Observation through `@ObservableState` (backported by
  TCA where needed) and `@Bindable` for navigation bindings.
- **MusicBrainz** provides artist search and detail data without an API key. Its rate limit and community-maintained metadata mean requests are paced and fields are treated as optional.
- **Default actor isolation is `nonisolated`.** Xcode's new-project default of
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` infers MainActor-isolated conformances for the
  `@Reducer` types. That produces a `circular reference` error while the compiler resolves
  `ReducerOf<Self>`. With the classic `nonisolated` default, SwiftUI views stay on the main actor
  through `View`, and the TCA `Store` is `@MainActor` itself.
- **Stack-based navigation (`StackState`)** instead of tree-based (`@Presents`). A list → detail
  flow is a natural push, and the stack scales if more screens are added.
- **Artist lookup loads up to 25 release groups** in one request, following MusicBrainz's lookup
  limit for linked entities.
- **Album covers use SwiftUI's `AsyncImage`, not a TCA dependency.** This is the one place where a
  network request bypasses the store, and it's on purpose: the cover is purely decorative, no
  reducer logic depends on it, and `AsyncImage` already handles loading, failure and cancellation.
  The strict TCA alternative (an `ImageClient` dependency plus per-row image state and actions in
  `ItemDetailFeature`) would make the images stubbable and testable with `TestStore`, but adds a
  lot of machinery for thumbnails in a demo app. In a production app that needed disk caching,
  offline support or tested image behaviour, I'd move image loading into a dependency.

_To be completed as the app takes shape: other fancy extra interactions and what I would do with more time._

## Tests

Tests use **Swift Testing** and TCA's `TestStore` to cover successful artist search, empty-query
validation, detail lookup, and navigation to the selected artist. API calls are replaced with mock
dependencies, so these tests do not depend on network availability.

## Use of AI tools

Claude (in Xcode) helped me deciding the initial TCA project structure, added the documentation comments
and this README. Then the rest of the codebase was added by the author and reviewed by Claude.
