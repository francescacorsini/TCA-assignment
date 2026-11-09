# TCA-assignment

Assignment about small iOS app using The Composable Architecture.

A small iOS app built with **SwiftUI** and **The Composable Architecture (TCA)**.
It has up to three screens on top of the public MusicBrainz REST API.

> **Status:** Artist search and artist detail are implemented with TCA. The detail screen shows the
> artist's release groups with album covers. Offline, rate-limit and decoding errors are handled,
> and the reducers and API client are covered by Swift Testing tests.

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
│   ├── MyApp.swift                 // @main entry point, creates the root Store
│   ├── AppFeature.swift            // Root reducer: composes features, owns the navigation stack
│   └── AppView.swift               // NavigationStack bound to AppFeature.State.path
├── Features/
│   ├── ItemList/
│   │   ├── ItemListFeature.swift   // Search screen reducer (idle / loading / loaded / failed)
│   │   └── ItemListView.swift      // Search screen view, with the system search field
│   └── ItemDetail/
│       ├── ItemDetailFeature.swift // Detail screen reducer: artist lookup and retry
│       └── ItemDetailView.swift    // Detail screen view, with album cover thumbnails
├── Models/
│   ├── Models.swift                // Decodable models for MusicBrainz artist and release-group data
│   ├── LoadingState.swift          // Generic idle / loading / loaded(Value) / failed state
│   └── Mocks.swift                 // Shared static mock data used by previews and tests
├── Dependencies/
│   └── APIClient/
│       └── APIClient.swift         // MusicBrainz client: live and preview values, error mapping
└── Assets.xcassets
Tests/
└── MyAppTests/
    ├── ItemListFeatureTests.swift   // Search reducer: success, blank query, errors
    ├── ItemDetailFeatureTests.swift // Detail reducer: lookup success and errors
    ├── AppFeatureTests.swift        // Navigation: selecting an artist pushes the detail screen
    └── APIClientTests.swift         // Live client: error mapping and request encoding (stubbed network)
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

No other third-party dependencies are used. Networking uses `URLSession`, and album covers use
SwiftUI's `AsyncImage`.

## Decisions and trade-offs

- **SwiftUI only.** No UIKit.
- **iOS 17 minimum.** This lets the views use Observation through `@ObservableState` (backported by
  TCA where needed) and `@Bindable` for navigation bindings.
- **MusicBrainz** provides artist search and detail data without an API key. Its rate limit and community-maintained metadata mean requests are paced and fields are treated as optional.
- **Swift 6 language mode** for the app and test targets, so data-race safety is checked at
  compile time.
- **Default actor isolation is set to `nonisolated`.** New Xcode projects default to
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which implicitly marks every type as `@MainActor`.
  With that setting, the `@Reducer` macro's generated `Reducer` conformance fails to compile with a
  "circular reference" error. Reverting to the classic `nonisolated` default fixes it without losing
  main-thread safety: SwiftUI `View`s are `@MainActor` through the `View` protocol, the TCA `Store`
  is `@MainActor` itself, and reducers are plain value types that the `Store` runs on the main actor.
- **One generic `LoadingState<Value>`** shared by both screens. The loaded data lives inside the
  `.loaded` case, so a screen can't show stale results while it is loading or has failed.
- **Typed API errors.** `APIClientError` maps no connection to `.offline`, HTTP 503 (MusicBrainz's
  rate-limit response) to `.rateLimited`, and malformed JSON to `.decoding`, each with a readable
  message. Cancelled requests become `CancellationError`, so a newer search silently replaces the
  previous one.
- **A blank search is not an error.** Submitting an empty query keeps the idle prompt and doesn't
  call the API.
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


## Tests

Tests use **Swift Testing** and TCA's `TestStore`, and none of them touch the real network:

- **Reducers:** successful search, blank-query handling, detail lookup, navigation to the selected
  artist, and the offline / rate-limited / decoding error messages on both screens. The API client
  is replaced with mock dependencies.
- **Live API client:** a stub `URLProtocol` intercepts requests to check how connection errors,
  cancellation, HTTP 503 / 500 and malformed JSON map to `APIClientError`, and that `+` in a search
  query is percent-encoded. This suite runs serially because the stub is shared state.

## Use of AI tools

Claude (in Xcode) helped me deciding the initial TCA project structure, added the documentation comments
and this README. Then the rest of the codebase was added by the author and reviewed by Claude.
