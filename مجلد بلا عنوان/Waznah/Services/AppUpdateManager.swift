//
//  AppUpdateManager.swift
//  Waznah
//

import FirebaseRemoteConfig
import Foundation

enum AppUpdateKind: Equatable {
    case none
    case optional(AppUpdateInfo)
    case required(AppUpdateInfo)
}

struct AppUpdateInfo: Equatable {
    let title: String
    let message: String
    let appStoreURL: String
    let latestVersion: String
}

final class AppUpdateManager {
    static let shared = AppUpdateManager()

    private let remoteConfig = RemoteConfig.remoteConfig()

    private enum Keys {
        static let enabled = "ios_update_enabled"
        static let minimumVersion = "ios_minimum_version"
        static let latestVersion = "ios_latest_version"
        static let title = "ios_update_title"
        static let message = "ios_update_message"
        static let forceUpdate = "ios_force_update"
        static let appStoreURL = "ios_app_store_url"
    }

    private static let infoPlistStoreURLKey = "WaznahAppStoreURL"
    private static let infoPlistPrivacyURLKey = "WaznahPrivacyPolicyURL"

    private init() {
        configureDefaults()
    }

    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// URL encoded in recipe PDF QR codes and used for App Store links when Remote Config is unset.
    static var appStoreShareURLString: String {
        shared.resolvedAppStoreURLString()
    }

    static var privacyPolicyURLString: String {
        shared.resolvedPrivacyPolicyURLString()
    }

    static var supportEmail: String {
        "anas.h.alhumaid@gmail.com"
    }

    func checkForUpdate() async -> AppUpdateKind {
        configureDefaults()

        do {
            _ = try await remoteConfig.fetchAndActivate()
        } catch {
            return .none
        }

        guard remoteConfig.configValue(forKey: Keys.enabled).boolValue else {
            return .none
        }

        let minimumVersion = remoteConfig.configValue(forKey: Keys.minimumVersion).stringValue
        let latestVersion = remoteConfig.configValue(forKey: Keys.latestVersion).stringValue

        let title = remoteConfig.configValue(forKey: Keys.title).stringValue
        let message = remoteConfig.configValue(forKey: Keys.message).stringValue
        let storeURL = resolvedAppStoreURLString()

        let current = currentAppVersion
        let needsMinimum = AppVersionComparator.isVersion(current, lessThan: minimumVersion)
        let needsLatest = AppVersionComparator.isVersion(current, lessThan: latestVersion)

        guard needsMinimum || needsLatest else {
            return .none
        }

        let info = AppUpdateInfo(
            title: title.isEmpty ? "Update required".localized() : title,
            message: message.isEmpty
                ? "Please update Waznah to continue using the app.".localized()
                : message,
            appStoreURL: storeURL,
            latestVersion: latestVersion.isEmpty ? minimumVersion : latestVersion
        )

        return .required(info)
    }

    private func resolvedAppStoreURLString() -> String {
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: Self.infoPlistStoreURLKey) as? String {
            let trimmed = plistURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        let remoteURL = remoteConfig.configValue(forKey: Keys.appStoreURL).stringValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !remoteURL.isEmpty, !remoteURL.contains("YOUR_APP_ID") {
            return remoteURL
        }

        return "https://apps.apple.com/search?term=Waznah+coffee"
    }

    private func resolvedPrivacyPolicyURLString() -> String {
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: Self.infoPlistPrivacyURLKey) as? String {
            let trimmed = plistURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return "mailto:\(Self.supportEmail)?subject=Waznah%20Privacy%20Policy"
    }

    private func configureDefaults() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3_600
        #endif
        remoteConfig.configSettings = settings

        remoteConfig.setDefaults([
            Keys.enabled: false as NSNumber,
            Keys.minimumVersion: "0" as NSString,
            Keys.latestVersion: "0" as NSString,
            Keys.title: "Update available" as NSString,
            Keys.message: "A new version of Waznah is available." as NSString,
            Keys.forceUpdate: false as NSNumber,
            Keys.appStoreURL: "" as NSString
        ])
    }
}

enum AppVersionComparator {
    static func isVersion(_ lhs: String, lessThan rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }

        guard !right.isEmpty, right != [0] else { return false }

        let count = max(left.count, right.count)
        for index in 0..<count {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l < r { return true }
            if l > r { return false }
        }

        return false
    }
}
