import Foundation
import CoreLocation

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
    /// The full docent-style narrative shown in the in-app popup.
    let story: String
    let keywords: [String]
    /// Asset catalog image names (Assets.xcassets) for photos taken at this site. Empty until added.
    let photos: [String]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func == (lhs: HistoricalSite, rhs: HistoricalSite) -> Bool {
        lhs.id == rhs.id
    }
}
