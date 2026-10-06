import SwiftUI

struct MemoryCard: View {
    var date: Date
    var note: String
    var mood: Mood?
    var petName: String
    var location: String?
    var assetLocalIdentifier: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let assetLocalIdentifier {
                AssetThumbnail(localIdentifier: assetLocalIdentifier)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Photo from \(petName)'s diary")
            }
            HStack {
                Text(date, format: .dateTime.month(.abbreviated).day().year())
                    .font(PawFont.body(.subheadline, weight: .semibold))
                    .foregroundStyle(PawColor.textSecondary)
                Spacer()
                if let mood {
                    Label(mood.title, systemImage: mood.symbolName)
                        .font(PawFont.body(.caption, weight: .semibold))
                        .foregroundStyle(PawColor.onPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PawColor.secondary, in: Capsule())
                        .accessibilityLabel("Mood, \(mood.title)")
                }
            }
            Text(note)
                .font(PawFont.body())
                .foregroundStyle(PawColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text(petName)
                    .font(PawFont.body(.footnote, weight: .semibold))
                    .foregroundStyle(PawColor.primary)
                if let location, !location.isEmpty {
                    Text("·")
                        .foregroundStyle(PawColor.textTertiary)
                        .accessibilityHidden(true)
                    Label(location, systemImage: "mappin")
                        .font(PawFont.body(.footnote))
                        .foregroundStyle(PawColor.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PawColor.surfaceElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PawColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    MemoryCard(
        date: .now,
        note: "She waited by the door like the walk was a ceremony.",
        mood: .proud,
        petName: "Bella",
        location: "Home"
    )
    .padding()
    .background(PawColor.background)
}
