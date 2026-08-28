import SwiftUI

struct SiteListView: View {
    let sites: [HistoricalSite]
    let onSelect: (HistoricalSite) -> Void

    var body: some View {
        NavigationStack {
            List(sites) { site in
                Button {
                    onSelect(site)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(site.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(site.category) · \(site.yearBuilt)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("치앙마이 유적지")
        }
    }
}
