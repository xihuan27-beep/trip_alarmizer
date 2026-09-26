import SwiftUI

struct SitePopupView: View {
    let site: HistoricalSite
    @ObservedObject private var audioPlayer = AudioPlayerManager.shared
    @State private var expandedSectionID: String?

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

                if !site.sections.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("둘러보기", systemImage: "list.bullet")
                        VStack(spacing: 10) {
                            ForEach(site.sections) { section in
                                SectionRow(
                                    site: site,
                                    section: section,
                                    isExpanded: expandedSectionID == section.id,
                                    onToggle: { toggleSection(section.id) }
                                )
                            }
                        }
                    }
                }

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

    private func toggleSection(_ id: String) {
        expandedSectionID = (expandedSectionID == id) ? nil : id
    }
}

/// One row in a multi-building site's "둘러보기" list — collapsed it shows
/// just the building's name and a one-line hook; tapping expands it to the
/// full story plus its own independent play/pause control, so a visitor
/// standing in front of one building only has to deal with that building's
/// worth of information at a time.
private struct SectionRow: View {
    let site: HistoricalSite
    let section: SiteSection
    let isExpanded: Bool
    let onToggle: () -> Void

    @ObservedObject private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(section.teaser)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(section.story)
                    .font(.callout)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !section.audioURLs.isEmpty {
                    audioButton
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private var isThisSectionPlaying: Bool {
        audioPlayer.playingSiteID == site.id && audioPlayer.playingSectionID == section.id && audioPlayer.isPlaying
    }

    private var isThisSectionPaused: Bool {
        audioPlayer.playingSiteID == site.id && audioPlayer.playingSectionID == section.id && !audioPlayer.isPlaying
    }

    private var audioButton: some View {
        Button {
            if isThisSectionPlaying {
                audioPlayer.pause()
            } else if isThisSectionPaused {
                audioPlayer.resume()
            } else {
                audioPlayer.play(site: site, section: section)
            }
        } label: {
            Label(
                isThisSectionPlaying ? "일시정지" : (isThisSectionPaused ? "이어서 듣기" : "이 건물 오디오 듣기"),
                systemImage: isThisSectionPlaying ? "pause.circle.fill" : "play.circle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
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
