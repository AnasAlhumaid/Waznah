//
//  FeaturedRecipes.swift
//  Waznah — curated roaster recipes bundled with the app ("Roaster Picks").
//
//  Source: Sulalat (sulalat.com) product pages. Pours are converted from the
//  roaster's cumulative targets into per-step amounts; step durations are
//  estimated from the published waits and total brew time.
//

import Foundation

struct FeaturedRecipe: Identifiable, Hashable {
    let id: String
    let roaster: String
    let crop: String
    let origin: String
    let process: String
    let tastingNotes: String
    let sourceURL: String
    let recipe: YourDataModelRes

    var displayTitle: String { "\(roaster.localized()) · \(crop.localized())" }
}

enum FeaturedRecipes {
    private static func step(_ title: String, water: Int, seconds: Int) -> StepsAndTimes {
        StepsAndTimes(step: title.localized(), time: "\(seconds)", water: "\(water)")
    }

    private static func make(
        id: String,
        crop: String,
        origin: String,
        process: String,
        notes: String,
        url: String,
        method: String,
        coffee: Int,
        water: Int,
        ratio: String,
        temp: Int,
        grind: String,
        steps: [StepsAndTimes]
    ) -> FeaturedRecipe {
        FeaturedRecipe(
            id: id,
            roaster: "Sulalat",
            crop: crop,
            origin: origin,
            process: process,
            tastingNotes: notes,
            sourceURL: url,
            recipe: YourDataModelRes(
                id: nil,
                rostery: "\("Sulalat".localized()) · \(crop.localized())",
                grain: grind.localized(),
                waterGrams: "\(water)",
                coffeeGrams: "\(coffee)",
                ratio: ratio,
                temp: "\(temp)",
                tool: method,
                field3: steps,
                ownerUid: nil,
                likeCount: nil,
                searchKeywords: nil,
                localRecipeId: nil
            )
        )
    }

    static var all: [FeaturedRecipe] { [
        make(
            id: "sulalat-alraheeq-v60",
            crop: "Al Raheeq",
            origin: "Saudi Arabia · Jazan",
            process: "Natural · Typica",
            notes: "Blackcurrant, cherry, lavender",
            url: "https://sulalat.com/products/alraheeq-natural-saudi-arabia",
            method: "V60", coffee: 18, water: 270, ratio: "1:15", temp: 93, grind: "Medium-fine",
            steps: [
                step("Bloom", water: 40, seconds: 40),
                step("Pour over the whole bed", water: 120, seconds: 30),
                step("Pour around the center", water: 70, seconds: 30),
                step("Pour in the center", water: 40, seconds: 25)
            ]
        ),
        make(
            id: "sulalat-halo-beriti-v60",
            crop: "Halo Beriti",
            origin: "Ethiopia · Guji",
            process: "Natural · Dega",
            notes: "Red berry, mango, orange, lavender",
            url: "https://sulalat.com/products/halo-beriti-natural-ethiopia",
            method: "V60", coffee: 19, water: 280, ratio: "1:14.7", temp: 93, grind: "Medium-fine",
            steps: [
                step("Bloom", water: 40, seconds: 40),
                step("Pour over the whole bed", water: 110, seconds: 30),
                step("Pour on the edges", water: 40, seconds: 30),
                step("Pour in the center", water: 90, seconds: 40)
            ]
        ),
        make(
            id: "sulalat-chelchele-v60",
            crop: "Chelchele",
            origin: "Ethiopia · Yirgacheffe",
            process: "Natural · Heirloom",
            notes: "Cherry, peach, jasmine",
            url: "https://sulalat.com/products/ethiopia-chelchele-natural",
            method: "V60", coffee: 22, water: 330, ratio: "1:15", temp: 94, grind: "Medium-fine",
            steps: [
                step("Bloom", water: 50, seconds: 40),
                step("Pour over the whole bed", water: 150, seconds: 55),
                step("Pour around the center", water: 80, seconds: 35),
                step("Pour in the center", water: 50, seconds: 50)
            ]
        ),
        make(
            id: "sulalat-chelchele-chemex",
            crop: "Chelchele",
            origin: "Ethiopia · Yirgacheffe",
            process: "Natural · Heirloom",
            notes: "Cherry, peach, jasmine",
            url: "https://sulalat.com/products/ethiopia-chelchele-natural",
            method: "Chemex", coffee: 20, water: 325, ratio: "1:16", temp: 95, grind: "Medium",
            steps: [
                step("Bloom", water: 50, seconds: 35),
                step("Pour over the whole bed", water: 150, seconds: 55),
                step("Pour around the center", water: 80, seconds: 35),
                step("Pour in the center", water: 45, seconds: 55)
            ]
        ),
        make(
            id: "sulalat-tico-pepe-v60",
            crop: "Tico Pepe",
            origin: "Colombia · Tolima",
            process: "Extended fermentation · Caturra",
            notes: "Tropical fruit, grape, orange blossom",
            url: "https://sulalat.com/products/tico-pepe-tolima-colombia",
            method: "V60", coffee: 19, water: 285, ratio: "1:15", temp: 94, grind: "Medium-fine",
            steps: [
                step("Bloom", water: 40, seconds: 40),
                step("Pour over the whole bed", water: 140, seconds: 30),
                step("Pour around the center", water: 60, seconds: 25),
                step("Pour in the center", water: 45, seconds: 45)
            ]
        ),
        make(
            id: "sulalat-el-tirra-v60",
            crop: "El Tirra",
            origin: "Costa Rica · San José",
            process: "Honey · Caturra",
            notes: "Blueberry, cherry, red grape",
            url: "https://sulalat.com/products/el-tirra-honey-costa-rica",
            method: "V60", coffee: 18, water: 275, ratio: "1:15", temp: 93, grind: "Medium-fine",
            steps: [
                step("Bloom", water: 40, seconds: 40),
                step("Pour over the whole bed", water: 120, seconds: 30),
                step("Pour on the edges", water: 70, seconds: 30),
                step("Pour in the center", water: 45, seconds: 50)
            ]
        )
    ] }
}
