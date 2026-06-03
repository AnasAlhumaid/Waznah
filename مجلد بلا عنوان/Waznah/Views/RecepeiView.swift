//
//  RecepeiView.swift
//  Waznah
//
//  Created by Anas Hamad on 11/5/23.
//

import SwiftUI

struct RecipeView: View {
    var recepi: Recepie?
    @Environment(\.managedObjectContext) var moc
    @StateObject private var cloudManager = FirestoreManager()
    @State private var isPublishing = false
    @State private var publishedCloudRecipeId: String?
    @State private var publishErrorMessage = ""
    @State private var showPublishError = false
    @State private var showPublishSuccess = false
    @State private var showShareCloudConfirmation = false
    @State private var showDeleteCloudConfirmation = false
    @State private var showDeleteCloudSuccess = false
    
    var body: some View {
        RecipeDetailSheet(
            roastery: recepi?.roastery ?? "Unknown roastery".localized(),
            method: recepi?.tools ?? "V60",
            coffee: recepi?.grain ?? "-",
            water: recepi?.prepare ?? "-",
            ratio: recepi?.ratio ?? "-",
            temperature: recepi?.temp ?? "-",
            grind: "-",
            notes: cleanNotes,
            steps: localSteps,
            sourceLabel: "Local Recipe".localized(),
            cloudActionTitle: currentCloudRecipeId == nil ? "Share to Community".localized() : "Remove from Community".localized(),
            cloudActionSystemImage: currentCloudRecipeId == nil ? "icloud.and.arrow.up.fill" : "trash.fill",
            cloudActionTint: currentCloudRecipeId == nil ? Color(hex: "#86373E") : Color(hex: "#A6423D"),
            isCloudActionLoading: isPublishing
        ) {
            if currentCloudRecipeId == nil {
                showShareCloudConfirmation = true
            } else {
                showDeleteCloudConfirmation = true
            }
        }
        .onAppear {
            publishedCloudRecipeId = storedCloudRecipeId
        }
        .alert("Shared to Community".localized(), isPresented: $showPublishSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Your local recipe is now public in Community Recipes.".localized())
        }
        .alert("Share to Community?".localized(), isPresented: $showShareCloudConfirmation) {
            Button("Agree".localized()) {
                publishToCloud()
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This recipe will be public in Community Recipes. Other anonymous users can see it and like it.".localized())
        }
        .alert("Remove from Community?".localized(), isPresented: $showDeleteCloudConfirmation) {
            Button("Delete".localized(), role: .destructive) {
                deleteFromCloud()
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This removes the public Community copy. Your local recipe stays saved.".localized())
        }
        .alert("Removed from Community".localized(), isPresented: $showDeleteCloudSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("This recipe is local only again.".localized())
        }
        .alert("Community action failed".localized(), isPresented: $showPublishError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(publishErrorMessage)
        }
    }
    
    private var currentCloudRecipeId: String? {
        publishedCloudRecipeId ?? storedCloudRecipeId
    }
    
    private var storedCloudRecipeId: String? {
        guard let value = recepi?.value(forKey: "cloudRecipeId") as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }
    
    private func publishToCloud() {
        guard currentCloudRecipeId == nil else {
            showDeleteCloudConfirmation = true
            return
        }
        
        guard let recepi else {
            publishErrorMessage = "Missing local recipe.".localized()
            showPublishError = true
            return
        }
        
        isPublishing = true
        cloudManager.publishLocalRecipe(
            localRecipeId: recepi.id?.uuidString ?? UUID().uuidString,
            roastery: recepi.roastery ?? "",
            grain: recepi.grain ?? "",
            waterGrams: recepi.prepare ?? "",
            coffeeGrams: recepi.grain ?? "",
            ratio: recepi.ratio ?? "",
            temp: recepi.temp ?? "",
            tool: recepi.tools ?? "V60",
            steps: localSteps
        ) { result in
            DispatchQueue.main.async {
                isPublishing = false
                
                switch result {
                case .success(let cloudId):
                    recepi.setValue(cloudId, forKey: "cloudRecipeId")
                    try? moc.save()
                    LocalRecipeSyncManager.shared.syncLocalRecipe(recepi)
                    publishedCloudRecipeId = cloudId
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showPublishSuccess = true
                    
                case .failure(let error):
                    publishErrorMessage = error.localizedDescription
                    showPublishError = true
                }
            }
        }
    }
    
    private func deleteFromCloud() {
        guard let cloudId = currentCloudRecipeId else {
            return
        }
        
        isPublishing = true
        cloudManager.deleteRecipe(id: cloudId) { error in
            DispatchQueue.main.async {
                isPublishing = false
                
                if let error = error {
                    if isStaleCommunityLinkError(error) {
                        recepi?.setValue(nil, forKey: "cloudRecipeId")
                        try? moc.save()
                        publishedCloudRecipeId = nil
                        publishErrorMessage = "This Community recipe belongs to a previous app install. The local link was cleared, but the public copy may still be visible.".localized()
                        showPublishError = true
                    } else {
                        publishErrorMessage = error.localizedDescription
                        showPublishError = true
                    }
                    return
                }
                
                recepi?.setValue(nil, forKey: "cloudRecipeId")
                try? moc.save()
                if let recepi {
                    LocalRecipeSyncManager.shared.syncLocalRecipe(recepi)
                }
                publishedCloudRecipeId = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showDeleteCloudSuccess = true
            }
        }
    }
    
    private func isStaleCommunityLinkError(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("permission")
            || message.contains("missing or insufficient")
            || message.contains("not authorized")
    }
    
    private var localSteps: [StepsAndTimes] {
        if let stepsData = recepi?.value(forKey: "stepsData") as? String,
           let data = stepsData.data(using: .utf8),
           let steps = try? JSONDecoder().decode([StepsAndTimes].self, from: data) {
            return steps
        }
        
        return legacyStepsFromNotes
    }
    
    private var cleanNotes: String {
        let notes = recepi?.more ?? ""
        guard let range = notes.range(of: "Brew steps:") else {
            return notes
        }
        
        return String(notes[..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var legacyStepsFromNotes: [StepsAndTimes] {
        let notes = recepi?.more ?? ""
        guard let range = notes.range(of: "Brew steps:") else {
            return []
        }
        
        let stepsText = notes[range.upperBound...]
        return stepsText
            .split(separator: "\n")
            .compactMap { line in
                parseLegacyStep(String(line))
            }
    }
    
    private func parseLegacyStep(_ line: String) -> StepsAndTimes? {
        let cleanedLine = line
            .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
        
        let parts = cleanedLine
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        guard !parts.isEmpty else { return nil }
        
        let step = parts[safe: 0] ?? ""
        let water = (parts[safe: 1] ?? "")
            .replacingOccurrences(of: "ml", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let time = (parts[safe: 2] ?? "")
            .replacingOccurrences(of: "sec", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return StepsAndTimes(step: step, time: time, water: water)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ShareSheet : UIViewControllerRepresentable{
    
    var iten : [Any]
    
    func makeUIViewController(context: Context) ->  UIActivityViewController {
        let controller = UIActivityViewController(activityItems: iten,applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        
    }
}


