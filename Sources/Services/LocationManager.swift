import Foundation
import CoreLocation
import UserNotifications

/// iOS limits an app to monitoring at most 20 CLCircularRegions at once,
/// so when there are more sites than that we keep re-registering the
/// regions nearest to the user's current location.
final class LocationManager: NSObject, ObservableObject {
    static let maxMonitoredRegions = 20

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var triggeredSite: HistoricalSite?

    private let manager = CLLocationManager()
    private let sites: [HistoricalSite]

    init(sites: [HistoricalSite]) {
        self.sites = sites
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        manager.startUpdatingLocation()
        refreshMonitoredRegions()
    }

    private func refreshMonitoredRegions() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        let candidateSites: [HistoricalSite]
        if let userLocation, sites.count > Self.maxMonitoredRegions {
            let userCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            candidateSites = sites
                .sorted {
                    CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: userCL) <
                    CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: userCL)
                }
                .prefix(Self.maxMonitoredRegions)
                .map { $0 }
        } else {
            candidateSites = Array(sites.prefix(Self.maxMonitoredRegions))
        }

        for site in candidateSites {
            let region = CLCircularRegion(center: site.coordinate, radius: site.radiusMeters, identifier: site.id)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }

    private func sendLocalNotification(for site: HistoricalSite) {
        let content = UNMutableNotificationContent()
        content.title = site.name
        content.body = site.teaser
        content.sound = .default
        let request = UNNotificationRequest(identifier: site.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startMonitoring()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        userLocation = latest.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let site = sites.first(where: { $0.id == region.identifier }) else { return }
        triggeredSite = site
        sendLocalNotification(for: site)
        refreshMonitoredRegions()
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        refreshMonitoredRegions()
    }
}
