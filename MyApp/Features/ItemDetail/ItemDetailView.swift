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

                    case let .loaded(artist) where artist.releaseGroups?.isEmpty ?? true:
                        ContentUnavailableView(
                            "No release groups",
                            systemImage: "opticaldisc",
                            description: Text("MusicBrainz has no release groups for this artist.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 160)

                    case let .loaded(artist):
                        ForEach(artist.releaseGroups ?? []) { releaseGroup in
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
            await store.send(.loadArtist).finish()
        }
    }

    private var artistInformation: some View {
        let artist = store.displayedArtist

        return VStack(alignment: .leading, spacing: 12) {
            Text(artist.name)
                .font(.largeTitle.bold())

            if let disambiguation = artist.disambiguation, !disambiguation.isEmpty {
                Text(disambiguation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Type", value: artist.type ?? "Unknown")

            if let location = artist.beginArea?.name ?? artist.area?.name {
                LabeledContent("Origin", value: location)
            }

            if let country = artist.country {
                LabeledContent("Country", value: country)
            }

            if let lifeSpan = artist.lifeSpan?.formattedRange {
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
                artist: Mocks.artist,
                status: .loaded(Mocks.artist)
            )) {
                ItemDetailFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
            }
        )
    }
}
