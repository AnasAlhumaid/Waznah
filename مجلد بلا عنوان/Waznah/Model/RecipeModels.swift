//
//  RecipeModels.swift
//  Waznah
//

import Foundation

struct StepsAndTimes: Hashable, Codable {
    var step: String
    var time: String
    var water: String
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
        lhs.isLikedByCurrentUser == rhs.isLikedByCurrentUser
    }

    private enum CodingKeys: String, CodingKey {
        case id, rostery, grain, waterGrams, coffeeGrams, ratio, temp, tool
        case field3, ownerUid, likeCount, searchKeywords, localRecipeId
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
