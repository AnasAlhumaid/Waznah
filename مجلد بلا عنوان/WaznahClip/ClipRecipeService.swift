//
//  ClipRecipeService.swift
//  WaznahClip — loads one Community recipe over Firestore REST.
//
//  The Firebase SDK is too large for the 15 MB App Clip budget, so the clip
//  signs in anonymously through the Identity Toolkit REST API (Firestore
//  rules require a signed-in user) and reads the document directly.
//

import Foundation

enum ClipRecipeError: LocalizedError {
    case missingConfig
    case notFound
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingConfig: return "App configuration is missing.".localized()
        case .notFound: return "Recipe not found".localized()
        case .server(let message): return message
        }
    }
}

final class ClipRecipeService {
    static let shared = ClipRecipeService()

    private let session = URLSession(configuration: .ephemeral)
    private var idToken: String?

    private lazy var config: (apiKey: String, projectId: String)? = {
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let plist = NSDictionary(contentsOf: url),
              let apiKey = plist["API_KEY"] as? String,
              let projectId = plist["PROJECT_ID"] as? String else { return nil }
        return (apiKey, projectId)
    }()

    func fetchRecipe(id: String) async throws -> YourDataModelRes {
        guard let config else { throw ClipRecipeError.missingConfig }
        let token = try await signInAnonymously(apiKey: config.apiKey)

        let escapedId = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        var request = URLRequest(url: URL(string:
            "https://firestore.googleapis.com/v1/projects/\(config.projectId)/databases/(default)/documents/recipes/\(escapedId)"
        )!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 404 { throw ClipRecipeError.notFound }
        guard status == 200 else { throw ClipRecipeError.server("Could not load recipe (\(status)).".localized()) }

        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fields = root["fields"] as? [String: Any] else { throw ClipRecipeError.notFound }

        var plain: [String: Any] = [:]
        for (key, value) in fields where key != "createdAt" && key != "updatedAt" {
            if let decoded = Self.plainValue(value) { plain[key] = decoded }
        }
        plain["id"] = id

        let json = try JSONSerialization.data(withJSONObject: plain)
        return try JSONDecoder().decode(YourDataModelRes.self, from: json)
    }

    private func signInAnonymously(apiKey: String) async throws -> String {
        if let idToken { return idToken }

        var request = URLRequest(url: URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["returnSecureToken": true])

        let (data, _) = try await session.data(for: request)
        guard let body = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = body["idToken"] as? String else {
            throw ClipRecipeError.server("Could not connect. Please try again.".localized())
        }
        idToken = token
        return token
    }

    /// Converts a Firestore REST typed value ({"stringValue": "…"} etc.) to plain JSON.
    private static func plainValue(_ value: Any) -> Any? {
        guard let typed = value as? [String: Any], let (type, raw) = typed.first else { return nil }
        switch type {
        case "stringValue", "booleanValue", "doubleValue":
            return raw
        case "integerValue":
            return Int(raw as? String ?? "") ?? raw
        case "arrayValue":
            let values = (raw as? [String: Any])?["values"] as? [Any] ?? []
            return values.compactMap(plainValue)
        case "mapValue":
            let fields = (raw as? [String: Any])?["fields"] as? [String: Any] ?? [:]
            return fields.compactMapValues(plainValue)
        default:
            return nil
        }
    }
}

/// Parses https://<host>/r/<id>[/brew] — same scheme as the full app's deep links.
enum ClipInvocation {
    static func recipeID(from url: URL) -> (id: String, startBrew: Bool)? {
        let parts = url.path.split(separator: "/").map(String.init)
        guard parts.count >= 2, parts[0].lowercased() == "r", !parts[1].isEmpty else { return nil }
        return (parts[1], parts.dropFirst(2).first?.lowercased() == "brew")
    }
}
