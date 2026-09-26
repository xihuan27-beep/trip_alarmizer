import Foundation
import CoreLocation

/// One building or distinct spot within a multi-building site (e.g. a
/// temple complex's main chedi vs. its viharn vs. its library). Sites with
/// only one thing to see have an empty `sections` array and rely solely on
/// the top-level `story`/`audioURLs`.
struct SiteSection: Identifiable, Codable, Equatable {
    let id: String
    /// Short label for this building/spot, e.g. "위한 루앙".
    let title: String
    /// One-line hook shown collapsed, before the visitor taps to expand.
    let teaser: String
    /// This section's own docent-style narrative.
    let story: String
    /// Narration audio URLs keyed by language code, same convention as
    /// `HistoricalSite.audioURLs`. Empty until this section's audio exists.
    let audioURLs: [String: String]
}

struct HistoricalSite: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let nameThai: String
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double
    let category: String
    let yearBuilt: String
    /// One catchy line shown as the push-notification body when the geofence triggers.
    let teaser: String
    /// The docent-style narrative shown in the in-app popup. For a
    /// multi-building site this is a short overview; the per-building detail
    /// lives in `sections` instead of being crammed in here.
    let story: String
    let keywords: [String]
    /// Asset catalog image names (Assets.xcassets) for photos taken at this site. Empty until added.
    let photos: [String]
    /// Narration audio URLs keyed by language code ("ko", "en", "zh", "th", "es", "de", "fr", "it", "ru").
    /// Empty for sites without a narration script yet. For a multi-building
    /// site this is the short overview narration; empty if there's no
    /// separate overview audio beyond the per-section ones.
    let audioURLs: [String: String]
    /// Individual buildings/spots to pick from, for sites big enough that
    /// dumping everything into one story/audio would overwhelm a visitor
    /// standing in front of just one building. Empty for single-building sites.
    let sections: [SiteSection]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: HistoricalSite, rhs: HistoricalSite) -> Bool {
        lhs.id == rhs.id
    }
}
