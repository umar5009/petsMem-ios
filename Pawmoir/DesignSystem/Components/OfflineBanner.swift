import SwiftUI

struct OfflineBanner: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "wifi.slash")
            .font(PawFont.body(.subheadline))
            .foregroundStyle(PawColor.textPrimary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PawColor.sageSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}
