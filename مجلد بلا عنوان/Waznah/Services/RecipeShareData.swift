//
//  RecipeShareData.swift
//  Waznah
//

import Foundation

struct RecipeShareData {
    let roastery: String
    let method: String
    let coffee: String
    let water: String
    let ratio: String
    let temperature: String
    let grind: String
    let notes: String
    let steps: [StepsAndTimes]
    let sourceLabel: String
    var cloudRecipeId: String? = nil
    
    var methodImageName: String {
        method == "Cold Brew" ? "Clod Brew" : method
    }
    
    var displayRoastery: String {
        let trimmed = roastery.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Recipe".localized() : trimmed
    }

    /// QR / share link — recipe deep link when published to Community, otherwise App Store.
    var shareURLString: String {
        if let cloudRecipeId, !cloudRecipeId.isEmpty {
            return WaznahDeepLink.recipeURL(recipeId: cloudRecipeId)
        }
        return AppUpdateManager.appStoreShareURLString
    }
    
    var pdfFileName: String {
        let base = displayRoastery
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let safe = base.isEmpty ? "Waznah-Recipe" : "Waznah-\(base)"
        return "\(safe).pdf"
    }
}
