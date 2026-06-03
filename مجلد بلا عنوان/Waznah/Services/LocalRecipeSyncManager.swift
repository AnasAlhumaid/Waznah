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
                completion(.failure(AuthServiceError.notSignedIn))
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
}
