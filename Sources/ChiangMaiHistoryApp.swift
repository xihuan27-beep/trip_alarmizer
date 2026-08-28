import SwiftUI
import GoogleMaps

@main
struct ChiangMaiHistoryApp: App {
    init() {
        GMSServices.provideAPIKey(APIKeys.googleMapsAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
