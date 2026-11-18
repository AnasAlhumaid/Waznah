//
//  BrewTimerAttributes.swift
//  Waznah — shared by the app and the WaznahTimerWidget extension.
//  Add this file to BOTH targets (Target Membership in the File inspector).
//

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Activity Attributes (shared with the widget extension)

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct BrewTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// When the timer reaches zero (only meaningful while running).
        var endDate: Date
        /// Seconds left when paused; nil while running.
        var pausedRemaining: Int?
        /// Total length, used for the progress bar.
        var totalSeconds: Int
        /// Main line, e.g. "Pour to 150 ml".
        var headline: String
        /// Secondary line, e.g. "Bloom · Step 1 of 4".
        var detail: String
    }

    var title: String
    var method: String
}
#endif
