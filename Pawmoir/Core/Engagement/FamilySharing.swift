import Foundation

/// Local stand-in for inviting family onto one pet. Premium only.
/// A real share will ride CloudKit once the iCloud container is on.
enum FamilySharing {
    static func makeCode(for petName: String) -> String {
        let prefix = petName.uppercased().filter(\.isLetter).prefix(4)
        let stem = prefix.isEmpty ? "PAW" : String(prefix)
        let number = Int.random(in: 1000...9999)
        return "\(stem)-\(number)"
    }
}
