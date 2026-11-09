import ComposableArchitecture
import SwiftUI

/// Lets the user search MusicBrainz and browse matching artists.
struct ItemListView: View {
    @Bindable var store: StoreOf<ItemListFeature>

    var body: some View {
        Group {
            switch store.status {
            case .idle:
                ContentUnavailableView(
                    "Search for an artist",
                    systemImage: "magnifyingglass",
                    description: Text("Enter an artist name to browse MusicBrainz.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loading:
                ProgressView("Searching MusicBrainz…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(response) where response.artists.isEmpty:
                ContentUnavailableView(
                    "No artists found",
                    systemImage: "music.note.list",
                    description: Text("Try another artist name.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .loaded(response):
                List(response.artists) { artist in
                    Button {
                        store.send(.delegate(.artistSelected(artist)))
                    } label: {
                        ArtistRow(artist: artist)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)

            case let .failed(message):
                ContentUnavailableView {
                    Label("Search failed", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        store.send(.retryButtonTapped)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Artists")
        // System search field: on iOS 26+ it renders as a Liquid Glass control
        // in the toolbar (bottom on iPhone), and the list scrolls beneath it.
        .searchable(
            text: Binding(
                get: { store.query },
                set: { store.send(.queryChanged($0)) }
            ),
            prompt: "Artist name"
        )
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .onSubmit(of: .search) { store.send(.searchButtonTapped) }
    }
}

private struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(artist.name)
                .font(.headline)

            // MusicBrainz can send empty strings for unknown fields, so drop those too.
            let metadata = [artist.type, artist.area?.name, artist.country]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            if !metadata.isEmpty {
                Text(metadata.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let disambiguation = artist.disambiguation, !disambiguation.isEmpty {
                Text(disambiguation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ItemListView(
            store: Store(initialState: ItemListFeature.State(
                query: "Radiohead",
                status: .loaded(Mocks.artistSearchResponse)
            )) {
                ItemListFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
            }
        )
    }
}
