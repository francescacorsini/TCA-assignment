// Sample data used by SwiftUI previews and tests.
final class Mocks {
    private init() {}

    /// A Radiohead artist with representative metadata and release groups for the detail preview.
    static let artist = Artist.mockRadiohead
    /// A sample MusicBrainz artist search response for the list preview.
    static let artistSearchResponse = ArtistSearchResponse.mockRadiohead
}

extension MusicBrainzArea {
    /// Sample country area used by the artist previews.
    static let mockEngland = MusicBrainzArea(id: "9f6e9d5a-3b5a-4a76-b3d3-a89c5b7e4b81", name: "England")
    /// Sample origin area used by the artist previews.
    static let mockAbingdon = MusicBrainzArea(id: "2df6d2a1-f4e4-4f9b-872b-e18e45a11bd1", name: "Abingdon")
}

extension ArtistLifeSpan {
    /// Sample lifespan for Radiohead.
    static let mockRadiohead = ArtistLifeSpan(begin: "1985", end: nil, ended: false)
}

extension ReleaseGroup {
    /// Sample Radiohead album release group.
    static let mockOKComputer = ReleaseGroup(
        id: "b1392450-e666-3926-a536-22c65f834433",
        title: "OK Computer",
        firstReleaseDate: "1997",
        primaryType: "Album"
    )

    /// Sample Radiohead album release group.
    static let mockInRainbows = ReleaseGroup(
        id: "6e335887-60ba-38f0-95af-fae7774336bf",
        title: "In Rainbows",
        firstReleaseDate: "2007",
        primaryType: "Album"
    )
}

extension Artist {
    /// Sample Radiohead record, including release groups for the detail screen preview.
    static let mockRadiohead = Artist(
        id: "a4f0b8b7-7e3a-4a1a-b8c8-2211cce4ca7e",
        name: "Radiohead",
        sortName: "Radiohead",
        type: "Group",
        country: "GB",
        area: .mockEngland,
        beginArea: .mockAbingdon,
        disambiguation: "UK alternative rock band",
        lifeSpan: .mockRadiohead,
        releaseGroups: [.mockOKComputer, .mockInRainbows]
    )
}

extension ArtistSearchResponse {
    /// Sample search response for the Radiohead query.
    static let mockRadiohead = ArtistSearchResponse(count: 1, offset: 0, artists: [.mockRadiohead])
}
