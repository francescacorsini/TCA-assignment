import Foundation

/// The paginated response returned by MusicBrainz artist search.
///
/// Endpoint: `GET /ws/2/artist/?query=artist:<term>&fmt=json&limit=<n>&offset=<n>`
struct ArtistSearchResponse: Decodable, Equatable {
    /// The total number of artists matching the query, across all pages.
    let count: Int
    /// The index of the first result in this page, as requested with the `offset` parameter.
    let offset: Int
    /// The artists in this page, ordered by relevance score (highest first).
    let artists: [Artist]
}

/// Artist data shared by search results and artist lookup responses.
///
/// - Search: `GET /ws/2/artist/?query=...&fmt=json`
/// - Lookup: `GET /ws/2/artist/{MBID}?inc=release-groups&fmt=json`
///
/// Most fields are optional because MusicBrainz omits them, or returns `null`,
/// when the data hasn't been entered for an artist.
struct Artist: Decodable, Equatable, Identifiable {
    /// The MusicBrainz identifier (MBID), a UUID string.
    let id: String
    /// The artist's official name, e.g. "Radiohead".
    let name: String
    /// The name used for sorting, e.g. "Beatles, The".
    let sortName: String?
    /// The artist type, e.g. "Person", "Group", "Orchestra", "Choir", "Character" or "Other".
    let type: String?
    /// The ISO 3166-1 alpha-2 code of the artist's main country, e.g. "GB".
    let country: String?
    /// The area the artist is primarily associated with (usually a country).
    let area: MusicBrainzArea?
    /// Where the artist began: birthplace for a person, formation place for a group.
    let beginArea: MusicBrainzArea?
    /// A short comment that tells apart artists with the same name.
    /// May be missing (search) or an empty string (lookup) when not set.
    let disambiguation: String?
    /// When the artist was active: birth/death for a person, formation/dissolution for a group.
    let lifeSpan: ArtistLifeSpan?
    /// The artist's release groups (albums, singles, EPs...).
    /// Only present in lookup responses requested with `inc=release-groups`, so always `nil` in
    /// search results. MusicBrainz caps linked entities in lookups at 25 items.
    let releaseGroups: [ReleaseGroup]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortName = "sort-name"
        case type
        case country
        case area
        case beginArea = "begin-area"
        case disambiguation
        case lifeSpan = "life-span"
        case releaseGroups = "release-groups"
    }
}

/// A geographic area (country, city, etc.) as embedded in artist responses.
struct MusicBrainzArea: Decodable, Equatable {
    /// The area's MBID.
    let id: String?
    /// The area's name, e.g. "United Kingdom" or "Abingdon".
    let name: String
}

/// The active period of an artist.
///
/// Dates are kept as `String` because MusicBrainz uses partial dates:
/// `"YYYY"`, `"YYYY-MM"` or `"YYYY-MM-DD"`.
struct ArtistLifeSpan: Decodable, Equatable {
    /// The start date (birth or formation), e.g. `"1985"`.
    let begin: String?
    /// The end date (death or dissolution). `nil` if the artist is still active or the date is unknown.
    let end: String?
    /// Whether the artist has ended. Search results often return `null` instead of `false`.
    let ended: Bool?
}

/// A release group: a logical album, single or EP, grouping all its editions
/// (e.g. the original and remastered releases of the same album).
struct ReleaseGroup: Decodable, Equatable, Identifiable {
    /// The release group's MBID.
    let id: String
    /// The title, e.g. "OK Computer".
    let title: String
    /// The date of the earliest release in the group, as a partial date (`"YYYY"`, `"YYYY-MM"`
    /// or `"YYYY-MM-DD"`). May be an empty string when unknown.
    let firstReleaseDate: String?
    /// The primary type: "Album", "Single", "EP", "Broadcast" or "Other". `nil` when not set.
    let primaryType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case firstReleaseDate = "first-release-date"
        case primaryType = "primary-type"
    }
}
