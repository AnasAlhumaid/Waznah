//
//  RecipeModels.swift
//  Waznah
//

import Foundation

extension String {
    /// Converts Arabic-Indic (٠-٩) and Persian (۰-۹) digits plus the Arabic decimal/thousands
    /// separators to ASCII, so numbers typed on an Arabic keyboard parse correctly.
    var westernDigits: String {
        var out = ""
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: out.append(Character(UnicodeScalar(scalar.value - 0x0660 + 48)!))
            case 0x06F0...0x06F9: out.append(Character(UnicodeScalar(scalar.value - 0x06F0 + 48)!))
            case 0x066B: out.append(".")   // ٫ Arabic decimal separator
            case 0x066C, 0x060C: out.append(",")  // ٬ thousands / ، Arabic comma
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out
    }
}

struct StepsAndTimes: Hashable, Codable {
    var step: String
    var time: String
    var water: String
}

// MARK: - Brew Journey

struct BrewJourneyStep: Identifiable, Hashable {
    let id: Int
    let title: String
    let pourAmountML: Double
    let targetTotalML: Double
    let durationSeconds: Int

    var hasTimer: Bool { durationSeconds > 0 }
}

enum BrewJourneyBuilder {
    static func parseVolume(_ value: String) -> Double? {
        let normalized = value.westernDigits
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "ml", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    static func formatVolume(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    static func parseDuration(_ value: String) -> Int {
        let normalized = value.westernDigits
            .replacingOccurrences(of: "sec", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "s", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let seconds = Int(normalized), seconds > 0 else { return 0 }
        return seconds
    }

    static func build(from steps: [StepsAndTimes]) -> [BrewJourneyStep] {
        var running = 0.0
        var journey: [BrewJourneyStep] = []

        for (index, step) in steps.enumerated() {
            guard let amount = parseVolume(step.water), amount > 0 else { continue }
            running += amount
            journey.append(
                BrewJourneyStep(
                    id: index,
                    title: step.step.trimmingCharacters(in: .whitespacesAndNewlines),
                    pourAmountML: amount,
                    targetTotalML: running,
                    durationSeconds: parseDuration(step.time)
                )
            )
        }

        return journey
    }

    static func totalWaterML(from steps: [StepsAndTimes]) -> Double? {
        let journey = build(from: steps)
        guard let last = journey.last else { return nil }
        return last.targetTotalML
    }
}

struct BrewJourneyRecipe: Hashable {
    let title: String
    let method: String
    let steps: [BrewJourneyStep]

    var totalWaterML: Double {
        steps.last?.targetTotalML ?? 0
    }

    /// Sum of all step durations — one continuous brew timer.
    var totalDurationSeconds: Int {
        steps.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Cumulative elapsed seconds at which each step ends.
    var stepEndElapsedSeconds: [Int] {
        var running = 0
        return steps.map { step in
            running += step.durationSeconds
            return running
        }
    }

    init(title: String, method: String, rawSteps: [StepsAndTimes]) {
        self.title = title
        self.method = method
        self.steps = BrewJourneyBuilder.build(from: rawSteps)
    }
}

struct YourDataModel: Identifiable {
    var id = UUID()
    var rostery: String
    var grainSize: String
    var waterGrams: String
    var coffeeGrams: String
    var ratio: String
    var temp: String
    var tool: String
    var field3: [[String: Any]]
}

struct YourDataModelRes: Codable, Hashable, Identifiable {
    var id: String?
    let rostery: String?
    let grain: String?
    let waterGrams: String?
    let coffeeGrams: String?
    let ratio: String?
    let temp: String?
    let tool: String?
    let field3: [StepsAndTimes]?
    let ownerUid: String?
    var likeCount: Int?
    let searchKeywords: [String]?
    let localRecipeId: String?
    var isLikedByCurrentUser = false

    // Structured crop info (optional — older/community recipes only have `rostery`).
    // Builds that don't know these keys simply ignore them when decoding.
    var crop: String? = nil
    var roaster: String? = nil
    var origin: String? = nil
    var process: String? = nil
    var tastingNotes: String? = nil
    /// "official" (roaster's own recipe), "waznah" (Waznah suggestion) or nil (community).
    var source: String? = nil
    /// Official xBloom share link (share-h5.xbloom.com/?id=…) that opens the recipe in the xBloom app.
    var xbloomURL: String? = nil

    static func == (lhs: YourDataModelRes, rhs: YourDataModelRes) -> Bool {
        lhs.rostery == rhs.rostery &&
        lhs.grain == rhs.grain &&
        lhs.waterGrams == rhs.waterGrams &&
        lhs.coffeeGrams == rhs.coffeeGrams &&
        lhs.ratio == rhs.ratio &&
        lhs.temp == rhs.temp &&
        lhs.tool == rhs.tool &&
        lhs.field3 == rhs.field3 &&
        lhs.ownerUid == rhs.ownerUid &&
        lhs.likeCount == rhs.likeCount &&
        lhs.searchKeywords == rhs.searchKeywords &&
        lhs.localRecipeId == rhs.localRecipeId &&
        lhs.isLikedByCurrentUser == rhs.isLikedByCurrentUser &&
        lhs.crop == rhs.crop &&
        lhs.roaster == rhs.roaster &&
        lhs.origin == rhs.origin &&
        lhs.process == rhs.process &&
        lhs.tastingNotes == rhs.tastingNotes &&
        lhs.source == rhs.source &&
        lhs.xbloomURL == rhs.xbloomURL
    }

    private enum CodingKeys: String, CodingKey {
        case id, rostery, grain, waterGrams, coffeeGrams, ratio, temp, tool
        case field3, ownerUid, likeCount, searchKeywords, localRecipeId
        case crop, roaster, origin, process, tastingNotes, source, xbloomURL
    }
}

enum RecipeSource: String, CaseIterable, Identifiable {
    case official
    case waznah
    case community

    var id: String { rawValue }

    var title: String {
        switch self {
        case .official: return "Official".localized()
        case .waznah: return "Waznah Pick".localized()
        case .community: return "Community".localized()
        }
    }

    var systemImage: String {
        switch self {
        case .official: return "checkmark.seal.fill"
        case .waznah: return "sparkles"
        case .community: return "person.2.fill"
        }
    }
}

extension YourDataModelRes {
    private static func clean(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    var recipeSource: RecipeSource {
        RecipeSource(rawValue: source ?? "") ?? .community
    }

    /// Big title: the crop when known, otherwise the free-text roastery field.
    var displayTitle: String {
        Self.clean(crop) ?? Self.clean(rostery) ?? "Untitled Recipe".localized()
    }

    /// Small line under the title, e.g. "Camel Step · Anaerobic".
    var displaySubtitle: String? {
        let parts = [Self.clean(roaster), Self.clean(process)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Only official xBloom https links are honoured, so a recipe can't open arbitrary URLs.
    var xbloomShareURL: URL? {
        guard let raw = Self.clean(xbloomURL), let url = URL(string: raw),
              url.scheme == "https", let host = url.host?.lowercased(),
              host == "xbloom.com" || host.hasSuffix(".xbloom.com") else { return nil }
        return url
    }

    var hasCropDetails: Bool {
        Self.clean(origin) != nil || Self.clean(process) != nil || Self.clean(tastingNotes) != nil
    }
}

enum CloudRecipeSort: String, CaseIterable, Identifiable {
    case newest
    case mostLiked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: return "Newest"
        case .mostLiked: return "Most liked"
        }
    }
}
