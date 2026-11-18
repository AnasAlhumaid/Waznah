//
//  LocalRecipeSyncManager.swift
//  Waznah
//

import CoreData
import FirebaseAuth
import FirebaseFirestore
import Foundation

final class LocalRecipeSyncManager {
    static let shared = LocalRecipeSyncManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    func syncLocalRecipe(_ recipe: Recepie, completion: ((Error?) -> Void)? = nil) {
        ensureAuthenticated { result in
            switch result {
            case .failure(let error):
                completion?(error)
            case .success(let uid):
                let localId = recipe.stableLocalID
                let payload = self.privateRecipePayload(from: recipe, localId: localId.uuidString)
                
                self.privateRecipesCollection(uid: uid)
                    .document(localId.uuidString)
                    .setData(payload, merge: true) { error in
                        completion?(error)
                    }
            }
        }
    }
    
    func deletePrivateRecipe(localId: String, completion: ((Error?) -> Void)? = nil) {
        ensureAuthenticated { result in
            switch result {
            case .failure(let error):
                completion?(error)
            case .success(let uid):
                self.privateRecipesCollection(uid: uid)
                    .document(localId)
                    .delete { error in
                        completion?(error)
                    }
            }
        }
    }

    func detachAllCloudLinks(in context: NSManagedObjectContext) {
        guard let recipes = try? context.fetch(Recepie.all) else { return }

        for recipe in recipes {
            recipe.setValue(nil, forKey: "cloudRecipeId")
        }

        try? context.save()
    }
    
    func pullRemoteRecipes(into context: NSManagedObjectContext, completion: ((Error?) -> Void)? = nil) {
        ensureAuthenticated { result in
            switch result {
            case .failure(let error):
                completion?(error)
            case .success(let uid):
                self.privateRecipesCollection(uid: uid)
                    .getDocuments { snapshot, error in
                        if let error {
                            completion?(error)
                            return
                        }
                        
                        context.perform {
                            let documents = snapshot?.documents ?? []
                            
                            for document in documents {
                                self.applyRemoteDocument(document, in: context)
                            }
                            
                            do {
                                if context.hasChanges {
                                    try context.save()
                                }
                                completion?(nil)
                            } catch {
                                completion?(error)
                            }
                        }
                    }
            }
        }
    }
    
    func syncAllLocalRecipes(in context: NSManagedObjectContext) {
        ensureAuthenticated { result in
            guard case .success = result else { return }
            
            let request = Recepie.all
            guard let recipes = try? context.fetch(request) else { return }
            
            for recipe in recipes {
                self.syncLocalRecipe(recipe)
            }
        }
    }
    
    private func ensureAuthenticated(completion: @escaping (Result<String, Error>) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            completion(.success(uid))
            return
        }
        
        Auth.auth().signInAnonymously { result, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(
                    domain: "Waznah.Sync",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not connect to our servers.".localized()]
                )))
                return
            }
            
            completion(.success(uid))
        }
    }
    
    func refresh(in context: NSManagedObjectContext, completion: ((Error?) -> Void)? = nil) {
        pullRemoteRecipes(into: context) { error in
            if error == nil {
                self.syncAllLocalRecipes(in: context)
            }
            completion?(error)
        }
    }
    
    private func privateRecipesCollection(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("recipes")
    }
    
    private func privateRecipePayload(from recipe: Recepie, localId: String) -> [String: Any] {
        var payload: [String: Any] = [
            "localId": localId,
            "roastery": recipe.roastery ?? "",
            "grain": recipe.grain ?? "",
            "prepare": recipe.prepare ?? "",
            "ratio": recipe.ratio ?? "",
            "temp": recipe.temp ?? "",
            "tools": recipe.tools ?? "",
            "more": recipe.more ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let stepsData = recipe.value(forKey: "stepsData") as? String, !stepsData.isEmpty {
            payload["stepsData"] = stepsData
        }
        
        if let cloudRecipeId = recipe.value(forKey: "cloudRecipeId") as? String, !cloudRecipeId.isEmpty {
            payload["cloudRecipeId"] = cloudRecipeId
        } else {
            payload["cloudRecipeId"] = FieldValue.delete()
        }

        // Store the share link exactly. Empty clears it so a removed link disappears on other devices.
        if let studio = recipe.xbloomStudioURLValue {
            payload["xbloomStudioURL"] = studio
        } else {
            payload["xbloomStudioURL"] = FieldValue.delete()
        }
        if let original = recipe.xbloomOriginalURLValue {
            payload["xbloomOriginalURL"] = original
        } else {
            payload["xbloomOriginalURL"] = FieldValue.delete()
        }
        
        payload["createdAt"] = FieldValue.serverTimestamp()
        return payload
    }
    
    private func applyRemoteDocument(_ document: QueryDocumentSnapshot, in context: NSManagedObjectContext) {
        let data = document.data()
        guard let localIdString = data["localId"] as? String,
              let localId = UUID(uuidString: localIdString) else {
            return
        }
        
        let recipe = Recepie.fetch(by: localId, in: context) ?? Recepie(context: context)
        recipe.id = localId
        recipe.roastery = data["roastery"] as? String
        recipe.grain = data["grain"] as? String
        recipe.prepare = data["prepare"] as? String
        recipe.ratio = data["ratio"] as? String
        recipe.temp = data["temp"] as? String
        recipe.tools = data["tools"] as? String
        recipe.more = data["more"] as? String
        
        if let stepsData = data["stepsData"] as? String {
            recipe.setValue(stepsData, forKey: "stepsData")
        }
        
        if let cloudRecipeId = data["cloudRecipeId"] as? String, !cloudRecipeId.isEmpty {
            recipe.setValue(cloudRecipeId, forKey: "cloudRecipeId")
        }

        recipe.setValue(data["xbloomStudioURL"] as? String, forKey: "xbloomStudioURL")
        recipe.setValue(data["xbloomOriginalURL"] as? String, forKey: "xbloomOriginalURL")
    }
}

extension Recepie {
    var stableLocalID: UUID {
        if let id {
            return id
        }
        
        let newId = UUID()
        self.id = newId
        return newId
    }
    
    static func fetch(by id: UUID, in context: NSManagedObjectContext) -> Recepie? {
        let request = NSFetchRequest<Recepie>(entityName: "Recepie")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    var decodedSteps: [StepsAndTimes] {
        if let stepsData = value(forKey: "stepsData") as? String,
           let data = stepsData.data(using: .utf8),
           let steps = try? JSONDecoder().decode([StepsAndTimes].self, from: data) {
            return steps
        }
        return legacyStepsFromNotes
    }

    var notesWithoutLegacySteps: String {
        let notes = more ?? ""
        guard let range = notes.range(of: "Brew steps:") else { return notes }
        return String(notes[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cloudRecipeIdValue: String? {
        guard let value = value(forKey: "cloudRecipeId") as? String, !value.isEmpty else { return nil }
        return value
    }

    /// Exact official share link, or nil. Invalid hosts are ignored so a bad sync can't open them.
    var xbloomStudioURLValue: String? { XBloomShareLink.preserved(value(forKey: "xbloomStudioURL") as? String) }

    var xbloomOriginalURLValue: String? { XBloomShareLink.preserved(value(forKey: "xbloomOriginalURL") as? String) }

    var xbloomRecipeLinks: XBloomRecipeLinks {
        XBloomRecipeLinks(studioURL: xbloomStudioURLValue, originalURL: xbloomOriginalURLValue, legacyURL: nil)
    }

    private var legacyStepsFromNotes: [StepsAndTimes] {
        let notes = more ?? ""
        guard let range = notes.range(of: "Brew steps:") else { return [] }
        return notes[range.upperBound...]
            .split(separator: "\n")
            .compactMap { Self.parseLegacyStep(String($0)) }
    }

    private static func parseLegacyStep(_ line: String) -> StepsAndTimes? {
        let cleanedLine = line.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
        let parts = cleanedLine.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !parts.isEmpty else { return nil }
        let step = parts[safe: 0] ?? ""
        let water = (parts[safe: 1] ?? "").replacingOccurrences(of: "ml", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let time = (parts[safe: 2] ?? "").replacingOccurrences(of: "sec", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return StepsAndTimes(step: step, time: time, water: water)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
