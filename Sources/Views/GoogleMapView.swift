import SwiftUI
import GoogleMaps
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    let sites: [HistoricalSite]
    let userLocation: CLLocationCoordinate2D?
    @Binding var selectedSite: HistoricalSite?

    func makeUIView(context: Context) -> GMSMapView {
        // Chiang Mai Old City center as the default camera position.
        let camera = GMSCameraPosition.camera(withLatitude: 18.7883, longitude: 98.9853, zoom: 14)
        let options = GMSMapViewOptions()
        options.camera = camera
        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.delegate = context.coordinator

        for site in sites {
            let marker = GMSMarker(position: site.coordinate)
            marker.title = site.name
            marker.snippet = site.category
            marker.userData = site.id
            marker.map = mapView
        }

        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        guard !context.coordinator.hasCenteredOnUser, let userLocation else { return }
        mapView.animate(toLocation: userLocation)
        context.coordinator.hasCenteredOnUser = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        let parent: GoogleMapView
        var hasCenteredOnUser = false

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let id = marker.userData as? String else { return false }
            parent.selectedSite = parent.sites.first { $0.id == id }
            return true
        }
    }
}
