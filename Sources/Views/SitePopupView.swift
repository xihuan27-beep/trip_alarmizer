import SwiftUI

struct SitePopupView: View {
    let site: HistoricalSite
    @ObservedObject private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(site.name)
                            .font(.title2)
                            .bold()
                        Text(site.nameThai)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Label(site.category, systemImage: "tag.fill")
                    Label(site.yearBuilt, systemImage: "clock.fill")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                if !site.audioURLs.isEmpty {
                    audioButton
                }

                if !site.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(site.photos, id: \.self) { photoName in
                                Image(photoName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 220, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                Divider()

                Text(site.teaser)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(site.story)
                    .font(.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if !site.keywords.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("핵심 키워드", systemImage: "number")
                        FlowKeywords(keywords: site.keywords)
                    }
                }
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var isThisSitePlaying: Bool {
        audioPlayer.playingSiteID == site.id && audioPlayer.isPlaying
    }

    private var isThisSitePaused: Bool {
        audioPlayer.playingSiteID == site.id && !audioPlayer.isPlaying
    }

    private var audioButton: some View {
        Button {
            if isThisSitePlaying {
                audioPlayer.pause()
            } else if isThisSitePaused {
                audioPlayer.resume()
            } else {
                audioPlayer.play(site: site)
            }
        } label: {
            Label(
                isThisSitePlaying ? "일시정지" : (isThisSitePaused ? "이어서 듣기" : "오디오로 듣기"),
                systemImage: isThisSitePlaying ? "pause.circle.fill" : "play.circle.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.orange)
    }
}

private struct FlowKeywords: View {
    let keywords: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(keywords, id: \.self) { keyword in
                Text("#\(keyword)")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
    }
}

/// Wraps its children onto multiple lines, left-to-right, like text.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, rowWidth)
        totalHeight += rowHeight
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
