//
//  WaznahDeepLink.swift
//  Waznah
//

import Foundation
import SwiftUI

enum WaznahDeepLinkDestination: Equatable {
    case openApp
    case recipe(id: String, startBrew: Bool)
}

enum WaznahDeepLink {
    private static let infoPlistBaseURLKey = "WaznahDeepLinkBaseURL"
    private static let customScheme = "waznah"

    /// Firebase Hosting base URL (no trailing slash).
    static var baseURLString: String {
        if let plist = Bundle.main.object(forInfoDictionaryKey: infoPlistBaseURLKey) as? String {
            let trimmed = plist.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
        }
        return "https://waznah-60781.web.app"
    }

    static var associatedDomains: [String] {
        guard let host = URL(string: baseURLString)?.host else {
            return ["waznah-60781.web.app", "waznah-60781.firebaseapp.com"]
        }
        if host.hasSuffix(".web.app") || host.hasSuffix(".firebaseapp.com") {
            return [host]
        }
        return [host, "waznah-60781.web.app", "waznah-60781.firebaseapp.com"]
    }

    static func recipeURL(recipeId: String, startBrew: Bool = false) -> String {
        let id = recipeId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return openURLString }
        if startBrew {
            return "\(baseURLString)/r/\(id)/brew"
        }
        return "\(baseURLString)/r/\(id)"
    }

    static var openURLString: String {
        "\(baseURLString)/open"
    }

    static func parse(_ url: URL) -> WaznahDeepLinkDestination? {
        if url.scheme?.lowercased() == customScheme {
            return parseCustomScheme(url)
        }
        return parseUniversalLink(url)
    }

    private static func parseCustomScheme(_ url: URL) -> WaznahDeepLinkDestination? {
        let host = (url.host ?? "").lowercased()
        let pathParts = url.path.split(separator: "/").map(String.init)

        switch host {
        case "recipe":
            guard let id = pathParts.first, !id.isEmpty else { return nil }
            let startBrew = pathParts.dropFirst().first?.lowercased() == "brew"
            return .recipe(id: id, startBrew: startBrew)
        case "open", "":
            return .openApp
        default:
            return nil
        }
    }

    private static func parseUniversalLink(_ url: URL) -> WaznahDeepLinkDestination? {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }

        let parts = url.path.split(separator: "/").map(String.init)
        guard let first = parts.first?.lowercased() else { return .openApp }

        switch first {
        case "open":
            return .openApp
        case "r":
            guard parts.count >= 2, !parts[1].isEmpty else { return nil }
            let startBrew = parts.dropFirst(2).first?.lowercased() == "brew"
            return .recipe(id: parts[1], startBrew: startBrew)
        default:
            return nil
        }
    }
}

@MainActor
final class WaznahDeepLinkRouter: ObservableObject {
    static let shared = WaznahDeepLinkRouter()

    @Published private(set) var pending: WaznahDeepLinkDestination?

    private init() {}

    func handle(url: URL) {
        guard let destination = WaznahDeepLink.parse(url) else { return }
        pending = destination
    }

    func consumePending() -> WaznahDeepLinkDestination? {
        defer { pending = nil }
        return pending
    }
}

struct DeepLinkRecipeLoader: View {
    let recipeId: String
    let startBrew: Bool
    let firestore: FirestoreManager
    let onDismiss: () -> Void

    @State private var recipe: YourDataModelRes?
    @State private var errorMessage = ""
    @State private var isLoading = true
    @State private var showFullRecipe = false

    var body: some View {
        ZStack {
            WaznahScreenBackground()

            if isLoading {
                ProgressView("Loading recipe...".localized())
            } else if let recipe {
                // Same short screen as the App Clip, so a bag QR feels identical with or without the app.
                RecipeQuickView(
                    recipe: recipe,
                    autoStartBrew: startBrew,
                    context: .fullApp(onClose: onDismiss, onShowDetails: { showFullRecipe = true })
                )
                .sheet(isPresented: $showFullRecipe) {
                    ApiRecepeiView(recepei: recipe, firestore: firestore)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: "#86373E"))
                    Text(errorMessage.isEmpty ? "Recipe not found".localized() : errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)
                    Button("Close".localized()) { onDismiss() }
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#86373E"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .task { await loadRecipe() }
    }

    private func loadRecipe() async {
        isLoading = true
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            firestore.fetchRecipe(recipeId: recipeId) { result in
                switch result {
                case .success(let model):
                    recipe = model
                    errorMessage = ""
                case .failure(let error):
                    recipe = nil
                    errorMessage = error.waznahUserFacingMessage
                }
                isLoading = false
                continuation.resume()
            }
        }
    }
}
