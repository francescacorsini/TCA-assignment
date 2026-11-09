import ComposableArchitecture
import SwiftUI

/// Shows the selected artist's information and MusicBrainz release groups.
struct ItemDetailView: View {
    /// The store driving the selected artist's detail feature.
    @Bindable var store: StoreOf<ItemDetailFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                artistInformation

                VStack(alignment: .leading, spacing: 12) {
                    Text("Release groups")
                        .font(.title2.bold())

                    switch store.status {
                    case .idle, .loading:
                        ProgressView("Loading releases…")
                            .frame(maxWidth: .infinity, minHeight: 120)

                    case .loaded where store.artist.releaseGroups?.isEmpty != false:
                        ContentUnavailableView(
                            "No release groups",
                            systemImage: "opticaldisc",
                            description: Text("MusicBrainz has no release groups for this artist.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 160)

                    case .loaded:
                        ForEach(store.artist.releaseGroups ?? []) { releaseGroup in
                            ReleaseGroupRow(releaseGroup: releaseGroup)
                        }

                    case let .failed(message):
                        ContentUnavailableView {
                            Label("Couldn't load releases", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(message)
                        } actions: {
                            Button("Try Again") {
                                store.send(.retryButtonTapped)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, minHeight: 160)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(store.artist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await store.send(.task).finish()
        }
    }

    private var artistInformation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.artist.name)
                .font(.largeTitle.bold())

            if let disambiguation = store.artist.disambiguation, !disambiguation.isEmpty {
                Text(disambiguation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Type", value: store.artist.type ?? "Unknown")

            if let location = store.artist.beginArea?.name ?? store.artist.area?.name {
                LabeledContent("Origin", value: location)
            }

            if let country = store.artist.country {
                LabeledContent("Country", value: country)
            }

            if let lifeSpan = store.artist.lifeSpan?.formattedRange {
                LabeledContent("Active", value: lifeSpan)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

private struct ReleaseGroupRow: View {
    let releaseGroup: ReleaseGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(releaseGroup.title)
                .font(.headline)

            let metadata = [releaseGroup.primaryType, releaseGroup.firstReleaseDate]
                .compactMap { $0 }
            if !metadata.isEmpty {
                Text(metadata.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(
            store: Store(initialState: ItemDetailFeature.State(
                artist: Artist(
                    id: "a4f0b8b7-7e3a-4a1a-b8c8-2211cce4ca7e",
                    name: "Radiohead",
                    sortName: "Radiohead",
                    type: "Group",
                    country: "GB",
                    area: MusicBrainzArea(id: nil, name: "England"),
                    beginArea: MusicBrainzArea(id: nil, name: "Abingdon"),
                    disambiguation: "UK alternative rock band",
                    lifeSpan: ArtistLifeSpan(begin: "1985", end: nil, ended: false),
                    releaseGroups: [
                        ReleaseGroup(
                            id: "release-group-1",
                            title: "OK Computer",
                            firstReleaseDate: "1997",
                            primaryType: "Album"
                        ),
                        ReleaseGroup(
                            id: "release-group-2",
                            title: "In Rainbows",
                            firstReleaseDate: "2007",
                            primaryType: "Album"
                        )
                    ]
                ),
                status: .loaded
            )) {
                ItemDetailFeature()
            }
        )
    }
}
