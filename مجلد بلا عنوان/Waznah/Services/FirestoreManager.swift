//
//  FirestoreManager.swift
//  Waznah
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirestoreManager: ObservableObject {
    @Published var fetchedData: [YourDataModelRes] = []
    @Published var isloading = false
    @Published var currentUserID: String?
    
    let db = Firestore.firestore()
    private var recipesListener: ListenerRegistration?

    func fetchDataFromFirestore(completion: @escaping ( Error?) -> Void) {
        DispatchQueue.main.async {
            self.isloading = true
        }
        
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isloading = false
                    completion(error)
                }
                
            case .success(let uid):
                self.recipesListener?.remove()
                self.recipesListener = self.publicRecipesCollection()
                    .order(by: "createdAt", descending: true)
                    .addSnapshotListener { (snapshot, error) in
               if let error = error {
                   print("Error getting documents: \(error)")
                   DispatchQueue.main.async {
                       self.isloading = false
                       completion(error)
                   }
                   return
               }

               let documents = snapshot?.documents ?? []
               var recipes = Array<YourDataModelRes?>(repeating: nil, count: documents.count)
               let group = DispatchGroup()

               for (index, document) in documents.enumerated() {
                   do {
                       let decoder = JSONDecoder()
                       
                     var data = document.data()
                       data.removeValue(forKey: "createdAt")
                       data.removeValue(forKey: "updatedAt")
                           let jsonData = try JSONSerialization.data(withJSONObject: data)
                           var model = try decoder.decode(YourDataModelRes.self, from: jsonData)
                       model.id = document.documentID
                       
                       group.enter()
                       self.recipeLikeDocument(recipeId: document.documentID, uid: uid).getDocument { likeSnapshot, _ in
                           model.isLikedByCurrentUser = likeSnapshot?.exists == true
                           recipes[index] = model
                           group.leave()
                       }
                    
                       
                   } catch {
                       print("Error decoding document: \(error)")
                   }
               }

               group.notify(queue: .main) {
                   self.fetchedData = recipes.compactMap { $0 }
                   self.isloading = false
                   completion(nil)
               }
           }
            }
        }
       }
    
    deinit {
        recipesListener?.remove()
    }

    func fetchRecipe(recipeId: String, completion: @escaping (Result<YourDataModelRes, Error>) -> Void) {
        let trimmedId = recipeId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            completion(.failure(NSError(domain: "Waznah", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Recipe not found".localized()
            ])))
            return
        }

        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }

            case .success(let uid):
                self.publicRecipesCollection().document(trimmedId).getDocument { snapshot, error in
                    if let error {
                        DispatchQueue.main.async { completion(.failure(error)) }
                        return
                    }

                    guard let snapshot, snapshot.exists, var data = snapshot.data() else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "Waznah", code: 404, userInfo: [
                                NSLocalizedDescriptionKey: "Recipe not found".localized()
                            ])))
                        }
                        return
                    }

                    do {
                        data.removeValue(forKey: "createdAt")
                        data.removeValue(forKey: "updatedAt")
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        var model = try JSONDecoder().decode(YourDataModelRes.self, from: jsonData)
                        model.id = snapshot.documentID

                        self.recipeLikeDocument(recipeId: trimmedId, uid: uid).getDocument { likeSnapshot, _ in
                            model.isLikedByCurrentUser = likeSnapshot?.exists == true
                            DispatchQueue.main.async { completion(.success(model)) }
                        }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                }
            }
        }
    }
    
    func createRecipe(data: YourDataModel, completion: @escaping (Error?) -> Void) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)
                
            case .success(let uid):
                let recipeRef = self.publicRecipesCollection().document()
                let recipeData = self.publicRecipePayload(
                    documentID: recipeRef.documentID,
                    ownerUid: uid,
                    roastery: data.rostery,
                    grain: data.grainSize,
                    waterGrams: data.waterGrams,
                    coffeeGrams: data.coffeeGrams,
                    ratio: data.ratio,
                    temp: data.temp,
                    tool: data.tool,
                    field3: data.field3,
                    localRecipeId: nil
                )
                
                recipeRef.setData(recipeData, merge: false) { error in
                    completion(error)
                }
            }
        }
    }
    
    func publishLocalRecipe(
        localRecipeId: String,
        roastery: String,
        grain: String,
        waterGrams: String,
        coffeeGrams: String,
        ratio: String,
        temp: String,
        tool: String,
        steps: [StepsAndTimes],
        xbloomStudioURL: String? = nil,
        xbloomOriginalURL: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let uid):
                let recipeRef = self.publicRecipesCollection().document()
                let recipeData = self.addingXBloomLinks(
                    self.publicRecipePayload(
                        documentID: recipeRef.documentID,
                        ownerUid: uid,
                        roastery: roastery,
                        grain: grain,
                        waterGrams: waterGrams,
                        coffeeGrams: coffeeGrams,
                        ratio: ratio,
                        temp: temp,
                        tool: tool,
                        field3: self.stepDictionaries(from: steps),
                        localRecipeId: localRecipeId
                    ),
                    studio: xbloomStudioURL,
                    original: xbloomOriginalURL,
                    deleteWhenMissing: false
                )
                
                recipeRef.setData(recipeData, merge: false) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(recipeRef.documentID))
                    }
                }
            }
        }
    }

    func updateSharedRecipe(
        cloudRecipeId: String,
        localRecipeId: String,
        roastery: String,
        grain: String,
        waterGrams: String,
        coffeeGrams: String,
        ratio: String,
        temp: String,
        tool: String,
        steps: [StepsAndTimes],
        xbloomStudioURL: String? = nil,
        xbloomOriginalURL: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)

            case .success:
                let payload = self.addingXBloomLinks(
                    self.publicRecipeUpdatePayload(
                        roastery: roastery,
                        grain: grain,
                        waterGrams: waterGrams,
                        coffeeGrams: coffeeGrams,
                        ratio: ratio,
                        temp: temp,
                        tool: tool,
                        field3: self.stepDictionaries(from: steps),
                        localRecipeId: localRecipeId
                    ),
                    studio: xbloomStudioURL,
                    original: xbloomOriginalURL,
                    deleteWhenMissing: true
                )

                self.publicRecipesCollection().document(cloudRecipeId).setData(payload, merge: true) { error in
                    completion(error)
                }
            }
        }
    }
    
    func deleteRecipe(id: String, completion: @escaping (Error?) -> Void) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)
                
            case .success:
                self.publicRecipesCollection().document(id).delete { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.fetchedData.removeAll { $0.id == id }
                        }
                    }
                    completion(error)
                }
            }
        }
    }

    func hasReportedRecipe(recipeId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let uid):
                let reportRef = self.db.collection("reports").document(Self.reportDocumentId(reporterUid: uid, recipeId: recipeId))
                reportRef.getDocument { snapshot, error in
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    completion(.success(snapshot?.exists == true))
                }
            }
        }
    }

    func reportRecipe(id: String, title: String, reason: String, completion: @escaping (Error?) -> Void) {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedReason.count >= 10 else {
            completion(RecipeReportValidationError.reasonTooShort)
            return
        }

        guard trimmedReason.count <= 500 else {
            completion(RecipeReportValidationError.reasonTooLong)
            return
        }

        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)

            case .success(let uid):
                let reportId = Self.reportDocumentId(reporterUid: uid, recipeId: id)
                let reportRef = self.db.collection("reports").document(reportId)

                let payload: [String: Any] = [
                    "recipeId": id,
                    "recipeTitle": title,
                    "reporterUid": uid,
                    "reason": trimmedReason,
                    "createdAt": FieldValue.serverTimestamp()
                ]

                reportRef.setData(payload) { error in
                    completion(error)
                }
            }
        }
    }

    private static func reportDocumentId(reporterUid: String, recipeId: String) -> String {
        "\(reporterUid)_\(recipeId)"
    }

    static func isPermissionDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == FirestoreErrorDomain && nsError.code == FirestoreErrorCode.permissionDenied.rawValue
    }

    func deleteCurrentUserAccount(completion: @escaping (Error?) -> Void) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)

            case .success(let uid):
                self.deletePublicRecipes(for: uid) { publicError in
                    if let publicError {
                        completion(publicError)
                        return
                    }

                    self.deletePrivateUserData(uid: uid) { privateError in
                        if let privateError {
                            completion(privateError)
                            return
                        }

                        guard let user = Auth.auth().currentUser else {
                            DispatchQueue.main.async {
                                self.currentUserID = nil
                                self.fetchedData = []
                            }
                            completion(nil)
                            return
                        }

                        user.delete { deleteError in
                            DispatchQueue.main.async {
                                self.recipesListener?.remove()
                                self.recipesListener = nil
                                self.currentUserID = nil
                                self.fetchedData = []
                            }
                            completion(deleteError)
                        }
                    }
                }
            }
        }
    }

    private func deletePublicRecipes(for uid: String, completion: @escaping (Error?) -> Void) {
        publicRecipesCollection()
            .whereField("ownerUid", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error {
                    completion(error)
                    return
                }

                let documents = snapshot?.documents ?? []
                guard !documents.isEmpty else {
                    completion(nil)
                    return
                }

                let group = DispatchGroup()
                var lastError: Error?

                for document in documents {
                    group.enter()
                    self.publicRecipesCollection().document(document.documentID).delete { error in
                        if let error {
                            lastError = error
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion(lastError)
                }
            }
    }

    private func deletePrivateUserData(uid: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(uid)
        let recipesRef = userRef.collection("recipes")

        recipesRef.getDocuments { snapshot, error in
            if let error {
                completion(error)
                return
            }

            let documents = snapshot?.documents ?? []
            let group = DispatchGroup()
            var lastError: Error?

            for document in documents {
                group.enter()
                recipesRef.document(document.documentID).delete { error in
                    if let error {
                        lastError = error
                    }
                    group.leave()
                }
            }

            group.notify(queue: .global()) {
                userRef.delete { deleteUserError in
                    completion(deleteUserError ?? lastError)
                }
            }
        }
    }
    
    func toggleLike(recipe: YourDataModelRes, completion: @escaping (Error?) -> Void) {
        guard let recipeId = recipe.id else {
            completion(NSError(
                domain: "Waznah.Firestore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing recipe id"]
            ))
            return
        }
        
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(error)
                
            case .success(let uid):
                let recipeRef = self.publicRecipesCollection().document(recipeId)
                let likeRef = self.recipeLikeDocument(recipeId: recipeId, uid: uid)
                
                self.db.runTransaction { transaction, errorPointer -> Any? in
                    do {
                        let recipeSnapshot = try transaction.getDocument(recipeRef)
                        let likeSnapshot = try transaction.getDocument(likeRef)
                        let currentCount = recipeSnapshot.data()?["likeCount"] as? Int ?? 0
                        
                        if likeSnapshot.exists {
                            transaction.deleteDocument(likeRef)
                            transaction.updateData(["likeCount": max(currentCount - 1, 0)], forDocument: recipeRef)
                            return false
                        } else {
                            transaction.setData([
                                "uid": uid,
                                "createdAt": FieldValue.serverTimestamp()
                            ], forDocument: likeRef)
                            transaction.updateData(["likeCount": currentCount + 1], forDocument: recipeRef)
                            return true
                        }
                    } catch let error as NSError {
                        errorPointer?.pointee = error
                        return nil
                    }
                } completion: { result, error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    let isLiked = (result as? Bool) ?? false
                    DispatchQueue.main.async {
                        if let index = self.fetchedData.firstIndex(where: { $0.id == recipeId }) {
                            let oldCount = self.fetchedData[index].likeCount ?? 0
                            self.fetchedData[index].isLikedByCurrentUser = isLiked
                            self.fetchedData[index].likeCount = isLiked ? oldCount + 1 : max(oldCount - 1, 0)
                        }
                    }
                    
                    completion(nil)
                }
            }
        }
    }
    
    private func ensureSignedIn(completion: @escaping (Result<String, Error>) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            DispatchQueue.main.async {
                self.currentUserID = uid
            }
            completion(.success(uid))
            return
        }
        
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let uid = result?.user.uid else {
                completion(.failure(NSError(
                    domain: "Waznah.FirebaseAuth",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not verify your account on our servers.".localized()]
                )))
                return
            }
            
            DispatchQueue.main.async {
                self.currentUserID = uid
            }
            completion(.success(uid))
        }
    }
    
    private func publicRecipesCollection() -> CollectionReference {
        db.collection("recipes")
    }
    
    private func recipeLikeDocument(recipeId: String, uid: String) -> DocumentReference {
        publicRecipesCollection().document(recipeId).collection("likes").document(uid)
    }
    
    private func publicRecipePayload(
        documentID: String,
        ownerUid: String,
        roastery: String,
        grain: String,
        waterGrams: String,
        coffeeGrams: String,
        ratio: String,
        temp: String,
        tool: String,
        field3: [[String: Any]],
        localRecipeId: String?
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "id": documentID,
            "ownerUid": ownerUid,
            "visibility": "public",
            "likeCount": 0,
            "rostery": roastery,
            "grain": grain,
            "waterGrams": waterGrams,
            "coffeeGrams": coffeeGrams,
            "ratio": ratio,
            "temp": temp,
            "tool": tool,
            "field3": field3,
            "searchKeywords": searchKeywords(
                roastery: roastery,
                grain: grain,
                waterGrams: waterGrams,
                coffeeGrams: coffeeGrams,
                ratio: ratio,
                temp: temp,
                tool: tool
            ),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let localRecipeId, !localRecipeId.isEmpty {
            payload["localRecipeId"] = localRecipeId
        }
        
        return payload
    }

    private func publicRecipeUpdatePayload(
        roastery: String,
        grain: String,
        waterGrams: String,
        coffeeGrams: String,
        ratio: String,
        temp: String,
        tool: String,
        field3: [[String: Any]],
        localRecipeId: String
    ) -> [String: Any] {
        [
            "rostery": roastery,
            "grain": grain,
            "waterGrams": waterGrams,
            "coffeeGrams": coffeeGrams,
            "ratio": ratio,
            "temp": temp,
            "tool": tool,
            "field3": field3,
            "localRecipeId": localRecipeId,
            "searchKeywords": searchKeywords(
                roastery: roastery,
                grain: grain,
                waterGrams: waterGrams,
                coffeeGrams: coffeeGrams,
                ratio: ratio,
                temp: temp,
                tool: tool
            ),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }

    /// Writes official share links unchanged. Invalid or empty values are omitted on create
    /// and removed on update, so a cleared link does not keep opening.
    private func addingXBloomLinks(
        _ payload: [String: Any],
        studio: String?,
        original: String?,
        deleteWhenMissing: Bool
    ) -> [String: Any] {
        var payload = payload
        func apply(_ key: String, _ value: String?) {
            if let exact = XBloomShareLink.preserved(value) {
                payload[key] = exact
            } else if deleteWhenMissing {
                payload[key] = FieldValue.delete()
            }
        }
        apply("xbloomStudioURL", studio)
        apply("xbloomOriginalURL", original)
        return payload
    }

    private func stepDictionaries(from steps: [StepsAndTimes]) -> [[String: Any]] {
        steps.map { step in
            [
                "step": step.step,
                "time": step.time,
                "water": step.water
            ]
        }
    }
    
    private func searchKeywords(
        roastery: String,
        grain: String,
        waterGrams: String,
        coffeeGrams: String,
        ratio: String,
        temp: String,
        tool: String
    ) -> [String] {
        [roastery, grain, waterGrams, coffeeGrams, ratio, temp, tool]
            .flatMap { value in
                value
                    .lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
            }
            .filter { !$0.isEmpty }
            .uniqued()
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

enum RecipeReportValidationError: LocalizedError, Equatable {
    case reasonTooShort
    case reasonTooLong
    case alreadyReported

    var errorDescription: String? {
        switch self {
        case .reasonTooShort:
            return "Please write at least 10 characters explaining why you are reporting this recipe.".localized()
        case .reasonTooLong:
            return "Report reason must be 500 characters or less.".localized()
        case .alreadyReported:
            return "You already reported this recipe.".localized()
        }
    }
}
