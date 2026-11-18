//
//  AppReviewPolicy.swift
//  Waznah
//
//  When the automatic "Rate the app" sheet may appear, and the App Store id
//  used when someone explicitly chooses to write a review.

import Foundation

enum AppReviewOutcome: String, Codable, Equatable {
    /// Not now, a swipe away, or "it's alright" without a note.
    case deferred
    /// They asked to review, or they sent feedback.
    case responded
}

struct AppReviewSnapshot: Codable, Equatable {
    var firstLaunchAt: Date?
    var activeDayCount: Int
    var lastActiveDay: String
    var positiveEventCount: Int
    var lastPromptAt: Date?
    var lastOutcome: AppReviewOutcome?

    static let empty = AppReviewSnapshot(
        firstLaunchAt: nil,
        activeDayCount: 0,
        lastActiveDay: "",
        positiveEventCount: 0,
        lastPromptAt: nil,
        lastOutcome: nil
    )
}

/// Gates for the automatic sheet. Release waits for real use across days.
/// Debug builds lower the gates so a couple of finished brews can show it.
struct AppReviewPolicy: Equatable {
    var minimumPositiveEvents: Int
    var minimumActiveDays: Int
    var minimumDaysSinceFirstLaunch: Int
    var deferralInterval: TimeInterval
    var responseInterval: TimeInterval

    /// Shipped behavior:
    /// - 3 finished timers, brew journeys, or newly saved recipes
    /// - the app opened on 2 different days
    /// - at least 2 calendar days since first launch
    /// - 45 days after a deferral, 120 days after a review or feedback
    /// The sheet is never evaluated at launch — only after one of those events.
    static let production = AppReviewPolicy(
        minimumPositiveEvents: 3,
        minimumActiveDays: 2,
        minimumDaysSinceFirstLaunch: 2,
        deferralInterval: 45 * 86_400,
        responseInterval: 120 * 86_400
    )

    /// Same-day testing: two positive events, then a 60-second quiet period.
    static let debug = AppReviewPolicy(
        minimumPositiveEvents: 2,
        minimumActiveDays: 1,
        minimumDaysSinceFirstLaunch: 0,
        deferralInterval: 60,
        responseInterval: 120
    )

    static var current: AppReviewPolicy {
        #if DEBUG
        return debug
        #else
        return production
        #endif
    }

    func canPromptAutomatically(
        snapshot: AppReviewSnapshot,
        now: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard let firstLaunch = snapshot.firstLaunchAt else { return false }
        guard snapshot.positiveEventCount >= minimumPositiveEvents else { return false }
        guard snapshot.activeDayCount >= minimumActiveDays else { return false }
        guard Self.calendarDays(from: firstLaunch, to: now, calendar: calendar) >= minimumDaysSinceFirstLaunch else {
            return false
        }

        if let lastPrompt = snapshot.lastPromptAt {
            let wait = snapshot.lastOutcome == .responded ? responseInterval : deferralInterval
            if now.timeIntervalSince(lastPrompt) < wait { return false }
        }

        return true
    }

    static func calendarDays(from start: Date, to end: Date, calendar: Calendar) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let days = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return max(days, 0)
    }

    /// Fixed examples so a debug launch catches a broken gate. Returns failure names.
    static func selfCheckFailures() -> [String] {
        var failures: [String] = []
        func expect(_ condition: Bool, _ name: String) {
            if !condition { failures.append(name) }
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
            var parts = DateComponents()
            parts.year = year
            parts.month = month
            parts.day = day
            parts.hour = 12
            return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
        }

        let policy = AppReviewPolicy.production
        var ready = AppReviewSnapshot.empty
        ready.firstLaunchAt = noon(2024, 1, 1)
        ready.activeDayCount = 2
        ready.positiveEventCount = 3

        expect(
            policy.canPromptAutomatically(snapshot: ready, now: noon(2024, 1, 3), calendar: calendar),
            "ready on the third calendar day"
        )
        expect(
            !policy.canPromptAutomatically(snapshot: ready, now: noon(2024, 1, 2), calendar: calendar),
            "still inside the first two days"
        )

        var fewEvents = ready
        fewEvents.positiveEventCount = 2
        expect(
            !policy.canPromptAutomatically(snapshot: fewEvents, now: noon(2024, 1, 6), calendar: calendar),
            "needs three positive events"
        )

        var oneDay = ready
        oneDay.activeDayCount = 1
        expect(
            !policy.canPromptAutomatically(snapshot: oneDay, now: noon(2024, 1, 6), calendar: calendar),
            "needs two active days"
        )

        var neverLaunched = ready
        neverLaunched.firstLaunchAt = nil
        expect(
            !policy.canPromptAutomatically(snapshot: neverLaunched, now: noon(2024, 1, 6), calendar: calendar),
            "needs a first launch"
        )

        let anchor = noon(2024, 6, 1)
        var deferred = ready
        deferred.firstLaunchAt = noon(2024, 1, 1)
        deferred.lastPromptAt = anchor
        deferred.lastOutcome = .deferred
        expect(
            !policy.canPromptAutomatically(
                snapshot: deferred,
                now: anchor.addingTimeInterval(policy.deferralInterval - 1),
                calendar: calendar
            ),
            "deferral still active"
        )
        expect(
            policy.canPromptAutomatically(
                snapshot: deferred,
                now: anchor.addingTimeInterval(policy.deferralInterval),
                calendar: calendar
            ),
            "deferral elapsed"
        )

        var responded = deferred
        responded.lastOutcome = .responded
        expect(
            !policy.canPromptAutomatically(
                snapshot: responded,
                now: anchor.addingTimeInterval(policy.deferralInterval),
                calendar: calendar
            ),
            "a response waits longer than a deferral"
        )
        expect(
            policy.canPromptAutomatically(
                snapshot: responded,
                now: anchor.addingTimeInterval(policy.responseInterval),
                calendar: calendar
            ),
            "response cooldown elapsed"
        )

        var missingOutcome = deferred
        missingOutcome.lastOutcome = nil
        expect(
            !policy.canPromptAutomatically(
                snapshot: missingOutcome,
                now: anchor.addingTimeInterval(policy.deferralInterval - 1),
                calendar: calendar
            ),
            "a prompt without an outcome still defers"
        )

        var debugReady = AppReviewSnapshot.empty
        debugReady.firstLaunchAt = noon(2024, 1, 1)
        debugReady.activeDayCount = 1
        debugReady.positiveEventCount = AppReviewPolicy.debug.minimumPositiveEvents
        expect(
            AppReviewPolicy.debug.canPromptAutomatically(
                snapshot: debugReady,
                now: noon(2024, 1, 1),
                calendar: calendar
            ),
            "debug policy allows the same day"
        )

        let listing = "https://apps.apple.com/sa/app/waznah-%D9%88%D8%B2%D9%86%D8%A9/id1609692144?l=ar"
        expect(WaznahAppStore.appID(in: listing) == "1609692144", "reads the listing id")
        expect(WaznahAppStore.appID(in: nil) == WaznahAppStore.fallbackAppID, "falls back when the url is missing")
        expect(
            WaznahAppStore.appID(in: "https://apps.apple.com/search?term=Waznah") == WaznahAppStore.fallbackAppID,
            "falls back when the url has no id"
        )

        return failures
    }
}

enum AppReviewFeedbackLimits {
    static let minimumCharacters = 8
    static let maximumCharacters = 800
}

enum WaznahAppStore {
    /// Numeric App Store id for Waznah (وزنة).
    /// This matches `WaznahAppStoreURL` in Info.plist (`id1609692144`).
    /// If that URL has no id, review links use this constant — update it if the listing changes.
    static let fallbackAppID = "1609692144"

    static var currentAppID: String {
        let plistURL = Bundle.main.object(forInfoDictionaryKey: "WaznahAppStoreURL") as? String
        return appID(in: plistURL)
    }

    static func appID(in storeURL: String?) -> String {
        guard let storeURL else { return fallbackAppID }
        let pattern = #"id([0-9]{6,})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: storeURL, range: NSRange(storeURL.startIndex..., in: storeURL)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: storeURL) else {
            return fallbackAppID
        }
        let digits = String(storeURL[range])
        return digits.isEmpty ? fallbackAppID : digits
    }

    /// User-initiated App Store review page. Not used to bypass the system prompt.
    static var writeReviewURL: URL {
        let id = currentAppID
        if let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") {
            return url
        }
        return URL(string: "https://apps.apple.com/app/id\(fallbackAppID)?action=write-review")!
    }

    /// Mail compose link. Feedback stays a private note to the developer.
    ///
    /// Recipe reports already live in Firestore, but there is no `feedback`
    /// collection in `firestore.rules`, and a write needs a signed-in user plus
    /// a rules publish. Mail uses the support address already shown in the brew
    /// info screen, so a note is not lost when Firebase config or rules are missing.
    static func mailtoURL(to address: String, subject: String, body: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")
        guard
            let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: allowed),
            let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: allowed)
        else { return nil }
        return URL(string: "mailto:\(address)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }
}
