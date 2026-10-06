import SwiftUI
import UIKit

struct PetAvatar: View {
    var imageData: Data?
    var name: String
    var species: PetSpecies
    var size: CGFloat = 72

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatar
                .frame(width: size, height: size)
                .clipShape(Circle())
            Image(systemName: species.symbolName)
                .font(.system(size: max(10, size * 0.22), weight: .semibold))
                .foregroundStyle(PawColor.onPrimary)
                .frame(width: size * 0.36, height: size * 0.36)
                .background(PawColor.secondary, in: Circle())
                .overlay(Circle().stroke(PawColor.background, lineWidth: 2))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(displayName), \(species.title)")
    }

    private var displayName: String {
        name.isEmpty ? "Pet" : name
    }

    @ViewBuilder
    private var avatar: some View {
        if let imageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                PawColor.coralSoft
                Text(initial)
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(PawColor.primary)
            }
        }
    }

    private var initial: String {
        let letter = displayName.first.map(String.init) ?? "P"
        return letter.uppercased()
    }
}

#Preview {
    HStack(spacing: 16) {
        PetAvatar(name: "Bella", species: .dog)
        PetAvatar(name: "Max", species: .cat, size: 56)
    }
    .padding()
    .background(PawColor.background)
}
