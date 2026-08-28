import Foundation

final class SiteDataStore {
    static let shared = SiteDataStore()

    let sites: [HistoricalSite]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "sites", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([HistoricalSite].self, from: data)
        else {
            assertionFailure("sites.json is missing or malformed")
            self.sites = []
            return
        }
        self.sites = decoded
    }
}
