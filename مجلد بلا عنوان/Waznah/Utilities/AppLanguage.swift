//
//  AppLanguage.swift
//  Waznah
//

import SwiftUI

enum AppLanguage {
    /// Active app language from Settings → General → Language & Region.
    static var preferredLanguageCode: String {
        if let bundleCode = Bundle.main.preferredLocalizations.first {
            return bundleCode
        }
        if let systemCode = Locale.preferredLanguages.first {
            return systemCode.split(separator: "-").first.map(String.init) ?? systemCode
        }
        return "en"
    }

    /// Whether the current system language reads right-to-left.
    static var isRightToLeft: Bool {
        NSLocale.characterDirection(forLanguage: preferredLanguageCode) == .rightToLeft
    }

    static var layoutDirection: LayoutDirection {
        isRightToLeft ? .rightToLeft : .leftToRight
    }
}

struct AppLanguageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, AppLanguage.layoutDirection)
    }
}

extension View {
    func appLanguageLayout() -> some View {
        modifier(AppLanguageModifier())
    }
}

extension Error {
    var waznahUserFacingMessage: String {
        let message = localizedDescription
        let lowered = message.lowercased()

        if lowered.contains("firebase")
            || lowered.contains("firestore")
            || lowered.contains("googleservice-info")
            || (lowered.contains("permission") && lowered.contains("insufficient")) {
            return "Something went wrong connecting to our servers. Please try again.".localized()
        }

        return message
    }
}

/// Optional hooks the main app registers. The App Clip leaves them empty, so a
/// finished brew there does not ask for a review.
enum WaznahEngagementCenter {
    static var brewJourneyAppeared: (() -> Void)?
    static var brewJourneyCompleted: (() -> Void)?
    static var brewJourneyRestarted: (() -> Void)?
    static var brewJourneyDismissed: (() -> Void)?
}
