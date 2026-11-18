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
    /// Older single xBloom share link. Still read so existing documents keep working.
    /// Device links below take over when either of them is set.
    var xbloomURL: String? = nil
    /// Official share link for xBloom Studio (`https://share-h5.xbloom.com/?id=…`).
    var xbloomStudioURL: String? = nil
    /// Official share link for xBloom Original. Grind settings differ from Studio.
    var xbloomOriginalURL: String? = nil

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
        lhs.xbloomURL == rhs.xbloomURL &&
        lhs.xbloomStudioURL == rhs.xbloomStudioURL &&
        lhs.xbloomOriginalURL == rhs.xbloomOriginalURL
    }

    private enum CodingKeys: String, CodingKey {
        case id, rostery, grain, waterGrams, coffeeGrams, ratio, temp, tool
        case field3, ownerUid, likeCount, searchKeywords, localRecipeId
        case crop, roaster, origin, process, tastingNotes, source
        case xbloomURL, xbloomStudioURL, xbloomOriginalURL
    }
}

// MARK: - xBloom share links

enum XBloomDevice: String, Hashable, Identifiable {
    case studio
    case original

    var id: String { rawValue }

    var title: String {
        switch self {
        case .studio: return "xBloom Studio".localized()
        case .original: return "xBloom Original".localized()
        }
    }
}

struct XBloomDeviceLink: Identifiable, Hashable {
    let device: XBloomDevice?
    /// Open this. Built so the percent-encoded id is unchanged.
    let url: URL
    /// The stored share link, character for character.
    let exact: String

    var id: String { (device?.rawValue ?? "legacy") + ":" + exact }
}

struct XBloomRecipeLinks: Hashable {
    var studioURL: String?
    var originalURL: String?
    /// Pre-device field. Used only when neither Studio nor Original is set.
    var legacyURL: String?

    static let empty = XBloomRecipeLinks()

    var choices: [XBloomDeviceLink] {
        var items: [XBloomDeviceLink] = []
        if let link = XBloomShareLink.link(from: studioURL) {
            items.append(XBloomDeviceLink(device: .studio, url: link.url, exact: link.exact))
        }
        if let link = XBloomShareLink.link(from: originalURL) {
            items.append(XBloomDeviceLink(device: .original, url: link.url, exact: link.exact))
        }
        if items.isEmpty, let link = XBloomShareLink.link(from: legacyURL) {
            items.append(XBloomDeviceLink(device: nil, url: link.url, exact: link.exact))
        }
        return items
    }

    var hasChoice: Bool { !choices.isEmpty }
}

/// Official xBloom share pages only. The id is often percent-encoded base64
/// (`%2F` for `/`, `%3D` for `=`). Decoding or re-encoding that id breaks the page,
/// so a valid link is returned exactly as it was stored.
enum XBloomShareLink {
    static let host = "share-h5.xbloom.com"

    /// Trimmed original string when `raw` is an official share link. Empty and invalid values are nil.
    static func preserved(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        guard isOfficialShareLink(trimmed) else { return nil }
        return trimmed
    }

    /// URL for SFSafariViewController. Nil when the link is missing, unofficial, or Foundation would rewrite the id.
    static func link(from raw: String?) -> (url: URL, exact: String)? {
        guard let exact = preserved(raw) else { return nil }
        guard let url = urlKeepingEncodedQuery(exact) else { return nil }
        return (url, exact)
    }

    static func rejectionMessage(studio: String, original: String) -> String? {
        let invalid = [studio, original].contains { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && preserved(trimmed) == nil
        }
        guard invalid else { return nil }
        return "That xBloom link must be an https://share-h5.xbloom.com/?id=… address.".localized()
    }

    private static func isOfficialShareLink(_ exact: String) -> Bool {
        // Parse the string by hand. URLComponents.query decodes `%2F` and `%3D`,
        // and writing those items back double-encodes them (`%252F`).
        let scheme = "https://"
        guard exact.hasPrefix(scheme) else { return false }
        let rest = exact.dropFirst(scheme.count)
        guard !rest.contains("@"),
              let boundary = rest.firstIndex(where: { $0 == "/" || $0 == "?" })
        else { return false }
        guard String(rest[..<boundary]) == host, !exact.contains("#") else { return false }
        let afterHost = rest[boundary...]
        if afterHost.hasPrefix("/") {
            let pathAndQuery = afterHost.dropFirst()
            guard pathAndQuery.hasPrefix("?") else { return false }
        } else if !afterHost.hasPrefix("?") {
            return false
        }
        guard let query = rawQuery(of: exact) else { return false }
        return hasNonEmptyID(query)
    }

    private static func urlKeepingEncodedQuery(_ exact: String) -> URL? {
        if let url = URL(string: exact), queryMatches(url, exact: exact) {
            return url
        }
        guard let query = rawQuery(of: exact) else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.percentEncodedPath = "/"
        // Already-encoded query. Assigning `queryItems` would decode `%2F`/`%3D` and encode them again.
        components.percentEncodedQuery = query
        guard let url = components.url, queryMatches(url, exact: exact) else { return nil }
        return url
    }

    private static func queryMatches(_ url: URL, exact: String) -> Bool {
        guard let expected = rawQuery(of: exact) else { return false }
        if rawQuery(of: url.absoluteString) == expected { return true }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           components.percentEncodedQuery == expected {
            return true
        }
        return false
    }

    private static func rawQuery(of urlString: String) -> String? {
        guard let queryStart = urlString.firstIndex(of: "?") else { return nil }
        let rest = urlString[urlString.index(after: queryStart)...]
        let query = rest.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        return query.isEmpty ? nil : query
    }

    private static func hasNonEmptyID(_ query: String) -> Bool {
        for part in query.split(separator: "&", omittingEmptySubsequences: false) {
            let piece = String(part)
            guard let separator = piece.firstIndex(of: "=") else { continue }
            let name = String(piece[..<separator])
            let value = String(piece[piece.index(after: separator)...])
            if name == "id", !value.isEmpty, value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
                return true
            }
        }
        return false
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

    var xbloomLinks: XBloomRecipeLinks {
        XBloomRecipeLinks(studioURL: xbloomStudioURL, originalURL: xbloomOriginalURL, legacyURL: xbloomURL)
    }

    /// Roaster picks are bundled, but their xBloom links live on the Firestore document
    /// so they can change without an app release. Server values replace bundled ones,
    /// including clearing a link by deleting the field.
    func applyingServerXBloomLinks(from server: YourDataModelRes?) -> YourDataModelRes {
        guard let server else { return self }
        var copy = self
        copy.xbloomURL = server.xbloomURL
        copy.xbloomStudioURL = server.xbloomStudioURL
        copy.xbloomOriginalURL = server.xbloomOriginalURL
        return copy
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
