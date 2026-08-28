import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager: LocationManager
    @State private var selectedSite: HistoricalSite?
    @State private var showList = false
    private let sites: [HistoricalSite]

    init() {
        let loadedSites = SiteDataStore.shared.sites
        self.sites = loadedSites
        _locationManager = StateObject(wrappedValue: LocationManager(sites: loadedSites))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GoogleMapView(sites: sites, userLocation: locationManager.userLocation, selectedSite: $selectedSite)
                .ignoresSafeArea(edges: .bottom)

            Button {
                showList = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title3)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(radius: 2)
            }
            .padding()
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestPermission()
            } else {
                locationManager.startMonitoring()
            }
        }
        .sheet(item: $selectedSite) { site in
            SitePopupView(site: site)
        }
        .sheet(isPresented: $showList) {
            SiteListView(sites: sites) { site in
                showList = false
                selectedSite = site
            }
        }
        .onChange(of: locationManager.triggeredSite) { newValue in
            guard let newValue else { return }
            selectedSite = newValue
        }
    }
}
