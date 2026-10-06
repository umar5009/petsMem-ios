import Foundation

/// Age in calendar time, plus a pet-years estimate.
///
/// The pet-years chart is a size-agnostic guide, not a veterinary diagnosis:
/// - First human year ≈ 15 pet years
/// - Second human year adds about 9 (24 at the second birthday)
/// - Each later year adds 5 for dogs (and other species) or 4 for cats
struct PetAge: Equatable, Sendable {
    enum Basis: String, Sendable {
        case birthday
        case gotchaDay
    }

    var years: Int
    var months: Int
    var days: Int
    var petYears: Int
    var basis: Basis

    var humanSummary: String {
        if years <= 0 && months <= 0 {
            let safeDays = max(days, 0)
            return safeDays == 1 ? "1 day" : "\(safeDays) days"
        }
        if years <= 0 {
            return months == 1 ? "1 month" : "\(months) months"
        }
        let yearText = years == 1 ? "1 year" : "\(years) years"
        if months <= 0 || years >= 5 {
            return yearText
        }
        let monthText = months == 1 ? "1 month" : "\(months) months"
        return "\(yearText), \(monthText)"
    }
}

enum PetAgeCalculator {
    static func age(
        species: PetSpecies,
        birthday: Date?,
        gotchaDay: Date?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> PetAge? {
        let basis: PetAge.Basis
        let start: Date
        if let birthday {
            basis = .birthday
            start = birthday
        } else if let gotchaDay {
            basis = .gotchaDay
            start = gotchaDay
        } else {
            return nil
        }

        guard start <= now else {
            return PetAge(years: 0, months: 0, days: 0, petYears: 0, basis: basis)
        }

        let parts = calendar.dateComponents([.year, .month, .day], from: start, to: now)
        let years = max(parts.year ?? 0, 0)
        let months = max(parts.month ?? 0, 0)
        let days = max(parts.day ?? 0, 0)
        return PetAge(
            years: years,
            months: months,
            days: days,
            petYears: petYears(species: species, years: years, months: months, days: days),
            basis: basis
        )
    }

    static func petYears(species: PetSpecies, years: Int, months: Int, days: Int) -> Int {
        let fractional = Double(years) + Double(months) / 12.0 + Double(days) / 365.0
        guard fractional > 0 else { return 0 }

        let laterYearStep: Double = species == .cat ? 4 : 5
        let value: Double
        if fractional < 1 {
            value = fractional * 15
        } else if fractional < 2 {
            value = 15 + (fractional - 1) * 9
        } else {
            value = 24 + (fractional - 2) * laterYearStep
        }
        return max(1, Int(value.rounded()))
    }
}
