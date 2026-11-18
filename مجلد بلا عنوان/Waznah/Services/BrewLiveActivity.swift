//
//  BrewLiveActivity.swift
//  Waznah — Lock Screen / Dynamic Island timer + "brew done" notification
//  App target only — BrewTimerAttributes lives in BrewTimerAttributes.swift.
//

import Foundation
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Controller (app side)

@MainActor
final class BrewLiveActivityController {
    static let shared = BrewLiveActivityController()
    private init() {}

    private var activity: Any?

    struct Snapshot {
        var title: String
        var method: String
        var remainingSeconds: Int
        var totalSeconds: Int
        var isRunning: Bool
        var headline: String
        var detail: String
    }

    func startOrUpdate(_ snapshot: Snapshot) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = BrewTimerAttributes.ContentState(
            endDate: Date().addingTimeInterval(TimeInterval(snapshot.remainingSeconds)),
            pausedRemaining: snapshot.isRunning ? nil : snapshot.remainingSeconds,
            totalSeconds: max(snapshot.totalSeconds, 1),
            headline: snapshot.headline,
            detail: snapshot.detail
        )

        if let current = activity as? Activity<BrewTimerAttributes> {
            Task { await current.update(using: state) }
            return
        }

        let attributes = BrewTimerAttributes(title: snapshot.title, method: snapshot.method)
        activity = try? Activity.request(attributes: attributes, contentState: state, pushType: nil)
        #endif
    }

    func end() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard let current = activity as? Activity<BrewTimerAttributes> else { return }
        activity = nil
        Task { await current.end(dismissalPolicy: .immediate) }
        #endif
    }
}

// MARK: - "Brew done" local notification

enum BrewTimerNotifier {
    private static let identifier = "waznah.brew.timer.done"

    /// Fires even when the app is in the background or the phone is locked.
    static func schedule(after seconds: Int, title: String) {
        cancel()
        guard seconds > 0 else { return }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "Your brew is ready. Enjoy your cup! ☕️".localized()
            content.sound = .default
            if #available(iOS 15.0, *) { content.interruptionLevel = .timeSensitive }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
