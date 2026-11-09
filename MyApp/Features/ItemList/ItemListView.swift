import ComposableArchitecture
import SwiftUI

/// Lets the user search MusicBrainz and browse matching artists.
struct ItemListView: View {
    @Bindable var store: StoreOf<ItemListFeature>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(
                    "Artist name",
                    text: Binding(
                        get: { store.query },
                        set: { store.send(.queryChanged($0)) }
                    )
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { store.send(.searchButtonTapped) }

                Button("Search") {
                    store.send(.searchButtonTapped)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.status == .loading)
            }
            .padding()

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

            case .loaded where store.artists.isEmpty:
                ContentUnavailableView(
                    "No artists found",
                    systemImage: "music.note.list",
                    description: Text("Try another artist name.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded:
                List(store.artists) { artist in
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
    }
}

private struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(artist.name)
                .font(.headline)

            let metadata = [artist.type, artist.area?.name, artist.country]
                .compactMap { $0 }
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
                artists: [
                    Artist(
                        id: "a4f0b8b7-7e3a-4a1a-b8c8-2211cce4ca7e",
                        name: "Radiohead",
                        sortName: "Radiohead",
                        type: "Group",
                        country: "GB",
                        area: MusicBrainzArea(id: nil, name: "England"),
                        beginArea: MusicBrainzArea(id: nil, name: "Abingdon"),
                        disambiguation: "UK alternative rock band",
                        lifeSpan: ArtistLifeSpan(begin: "1985", end: nil, ended: false),
                        releaseGroups: nil
                    )
                ],
                status: .loaded
            )) {
                ItemListFeature()
            }
        )
    }
}
