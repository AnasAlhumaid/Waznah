//
//  ApiRecepeiScreen.swift
//  Waznah
//
//  Created by Anas Hamad on 11/5/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ApiRecepeiView: View {
    
    var recepei : YourDataModelRes
    var body: some View {
        RecipeDetailSheet(
            roastery: recepei.rostery ?? "Unknown roastery".localized(),
            method: recepei.tool ?? "V60",
            coffee: recepei.coffeeGrams ?? "-",
            water: recepei.waterGrams ?? "-",
            ratio: recepei.ratio ?? "-",
            temperature: recepei.temp ?? "-",
            grind: recepei.grain ?? "-",
            notes: "",
            steps: recepei.field3 ?? [],
            sourceLabel: "Community Recipe".localized()
        )
    }
}

struct RecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
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
    var cloudActionTitle: String? = nil
    var cloudActionSystemImage = "icloud.and.arrow.up.fill"
    var cloudActionTint = Color(hex: "#86373E")
    var isCloudActionLoading = false
    var cloudAction: (() -> Void)? = nil
    
    private var methodImageName: String {
        method == "Cold Brew" ? "Clod Brew" : method
    }
    
    private var shareText: String {
        var text = """
        Waznah Recipe
        
        \(roastery)
        Method: \(method)
        Coffee: \(coffee)
        Water: \(water)
        Ratio: \(ratio)
        Temp: \(temperature)
        Grind: \(grind)
        """
        
        if !notes.isEmpty {
            text += "\n\nNotes: \(notes)"
        }
        
        if !steps.isEmpty {
            text += "\n\nSteps:"
            for (index, step) in steps.enumerated() {
                text += "\n\(index + 1). \(step.step) - \(step.water) ml - \(step.time) sec"
            }
        }
        
        return text
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    pageShareButton
                    heroCard
                    cloudActionButton
                    metricsGrid
                    stepsSection
                    notesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Recipe Details".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundColor(Color(hex: "#86373E"))
                            .frame(width: 48, height: 48)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var pageShareButton: some View {
        HStack {
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color(hex: "#86373E"))
                    .frame(width: 48, height: 48)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
    }
    
    private var heroCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#86373E").opacity(0.08))
                    .frame(width: 150, height: 150)
                
                Image(methodImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
            }
            
            VStack(spacing: 6) {
                Text(roastery.isEmpty ? "Untitled Recipe".localized() : roastery)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(method, systemImage: "mug.fill")
                    Text("•")
                    Text(sourceLabel)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(hex: "#86373E"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
        )
    }
    
    @ViewBuilder
    private var cloudActionButton: some View {
        if let cloudAction, let cloudActionTitle {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                cloudAction()
            } label: {
                HStack(spacing: 10) {
                    if isCloudActionLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: cloudActionSystemImage)
                    }
                    
                    Text(cloudActionTitle)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(cloudActionTint)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: cloudActionTint.opacity(0.16), radius: 14, x: 0, y: 8)
            }
            .disabled(isCloudActionLoading)
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailMetricCard(icon: "circle.hexagongrid", title: "Coffee".localized(), value: coffee, tint: Color(hex: "354449"))
            DetailMetricCard(icon: "drop.fill", title: "Water".localized(), value: water, tint: Color(hex: "648981"))
            DetailMetricCard(icon: "percent", title: "Ratio".localized(), value: ratio, tint: Color(hex: "BF8A6E"))
            DetailMetricCard(icon: "thermometer.medium", title: "Temp".localized(), value: temperature, tint: Color(hex: "8F7469"))
            DetailMetricCard(icon: "circle.dotted", title: "Grind".localized(), value: grind, tint: Color(hex: "ABAEA5"))
        }
    }
    
    @ViewBuilder
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brew Steps".localized())
                .font(.title3.weight(.bold))
            
            if steps.isEmpty {
                Text("No brew steps added yet.".localized())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "#86373E"))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.step.isEmpty ? "Pour".localized() : step.step)
                                .font(.headline)
                            
                            HStack(spacing: 14) {
                                Label("\(step.water) ml", systemImage: "drop.fill")
                                Label("\(step.time) sec", systemImage: "timer")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes".localized())
                    .font(.title3.weight(.bold))
                
                Text(notes)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
}

struct DetailMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(tint)
                .clipShape(Circle())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value.isEmpty ? "-" : value)
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

//#Preview {
//    ApiRecepeiView()
//}



struct TimerViewApi: View {
    @State private var selectedTime: Int = 150 // Default time in seconds
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    @State private var isPaused: Bool = true
    @State private var showTimer: Bool = false
    
    var body: some View {
       
            VStack {
                ZStack {
               
                    
                    
                    VStack {
                        Text("\(timeFormatted(elapsedTime))")
                            .font(.largeTitle)
                        
                        HStack {
                            Button(action: {
                                if isPaused {
                                    startTimer()
                                } else {
                                    pauseTimer()
                                }
                            }) {
                                Text(isPaused ? "Start".localized() : "Pause".localized())
                                    .foregroundColor(.white)
                                    .frame(width: 70,height: 30)
                                    .shadow(radius: 1)
                                    .background(Color("greenN"))
                                    .cornerRadius(10)
                                
                            }
                            
                            Button(action: {
                                stopTimer()
                            }) {
                                Text("Stop".localized())
                                    .foregroundColor(.white)
                                    .frame(width: 70,height: 30)
                                    .shadow(radius: 1)
                                    .background(Color("redN"))
                                    .cornerRadius(10)
                                    
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                }
              
                .padding()
                
                
                
             

               
                
            }
            .padding()
          
            .cornerRadius(15)
        }
     
        
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if elapsedTime < selectedTime {
                elapsedTime += 1
            } else {
                resetTimer()
            }
        }
        isPaused = false
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        isPaused = true
    }
    
    private func stopTimer() {
        resetTimer()
        isPaused = false
    }
    
    private func resetTimer() {
        timer?.invalidate()
        elapsedTime = 0
    }
    private func timeFormatted(_ totalSeconds: Int) -> String {
        let minutes: Int = totalSeconds / 60
        let seconds: Int = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
 
}
struct RecepeiCardApi: View {
    
    let recepi : RecepeiApi
   
   
    var body: some View {
        VStack(alignment: .leading){
            
            HStack{
          
                   
                
                VStack(alignment: .leading){
                  
                        VStack{
                            Text(recepi.roastery)
                                .font(.title2)
                            Text(recepi.tool)
                                .font(.title3)
                        }
                        
                     
                      
                     

                     
                            
                  
                    VStack(alignment: .leading){
                        HStack{
                            Image(systemName: "circle.hexagongrid")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "354449"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Grams Bean:".localized())
                                    .font(.caption)
                                Text("\(recepi.grain)")
                                    .font(.caption)
                            }
                            
                            Image(systemName: "drop")
                                .resizable()
                                .frame(width: 8,height: 8)  .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "648981"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Water:".localized())
                                    .font(.caption)
                                Text("\(recepi.water)")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .frame(width: 250)
                        
                        HStack{
                            Image(systemName: "percent")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "BF8A6E"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Ratio:".localized())
                                    .font(.caption)
                                Text("\(recepi.ration)")
                                    .font(.caption)
                            }
                            
                            Image(systemName: "thermometer.medium")
                                .resizable()
                                .frame(width: 8,height: 8)
                                .padding(6)
                                .foregroundColor(.white)
                                .background(Color(hex: "8F7469"))
                                .clipShape(Circle())
                            HStack(spacing:0){
                                Text("Temp:".localized())
                                    .font(.caption)
                                Text("\(recepi.temp)")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .frame(width: 250)
                        
                        
                    }
                    
                }
                
            }
            
           
            
        }
        .frame(width: size.width - 40 ,height: 130)
        .background(
            .thinMaterial
        )
       
    }
}




//struct StepsAndTimes: Identifiable {
//    let id: Int
//    let description: String
//    let phaseDuration: TimeInterval
//}

struct CoffeeDripView: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var currentPhase = 0
    @State var timer: Timer?
    var phaseData: [StepsAndTimes]
   
    
    var body: some View {
        VStack{
            Text("Steps".localized())
            
            ForEach(phaseData,id: \.self) { datum in
                
//                Text( datum.step)
//                Text("\(datum.time)")
//                Text(datum.water)
                
                
                HStack{
                    VStack{
                       
                        Text(datum.step)
                            .lineLimit(3)
                    }
                    Spacer()
                    VStack{
                        Text("Time".localized())
                        HStack(spacing:2){
                            Text(datum.time)
                            Text("sec")
                        }
                    }
                    
                    Spacer()
                    VStack{
                        Text("Gram".localized())
                        Text(datum.water)
                    }
                }
                .padding()
                .frame(width: size.width - 40)
                .background(.thinMaterial)
                .cornerRadius(10)
            }
        }
      
     
    }

    func startTimer() {
          guard currentPhase < phaseData.count else {
              print("No phases available")
              return
          }

          let phaseEndTime = phaseData[currentPhase].time

//          timer?.invalidate()
//          timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//              withAnimation {
//                  self.elapsedTime += 1
//              }
//              if self.elapsedTime >= phaseEndTime {
//                  self.timer?.invalidate()
//                  startNextPhase()
//              }
//          }
      }
//    func startNextPhase() {
//        elapsedTime = 0
//        guard currentPhase < phaseData.count else {
//            // Handle the case where there are no more phases
//            print("No more phases")
//            return
//        }
//
//        let currentPhaseDuration = phaseData[currentPhase].time
//        elapsedTime += currentPhaseDuration
//
//        let nextPhaseIndex = currentPhase + 1
//        if nextPhaseIndex < phaseData.count {
//            let nextPhaseDuration = phaseData[nextPhaseIndex].time
//            let totalDuration = elapsedTime + nextPhaseDuration
//
//            timer?.invalidate()
//
//            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                withAnimation {
//                    self.elapsedTime += 1
//                }
//                if self.elapsedTime >= totalDuration {
//                    self.timer?.invalidate()
//                    // Optionally start another phase or handle completion
//                }
//            }
//
//            currentPhase += 1  // Move to the next phase
//        } else {
//            // Handle the case where there are no more phases
//            print("No more phases")
//        }
//    }



    func phaseDescription(_ phase: Int) -> String {
        guard phase >= 0 && phase < phaseData.count else {
            return "No Phase"
        }
        return phaseData[phase].step
    }

    func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        let minutes = (seconds % 3600) / 60
        let hours = seconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds % 60)
    }
    
 
}
//
//struct ContentView: View {
//    var body: some View {
//        CoffeeDripView()
//    }
//}
//
//@main
//struct YourApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

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
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        ensureSignedIn { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let uid):
                let recipeRef = self.publicRecipesCollection().document()
                let stepDictionaries = steps.map { step in
                    [
                        "step": step.step,
                        "time": step.time,
                        "water": step.water
                    ]
                }
                let recipeData = self.publicRecipePayload(
                    documentID: recipeRef.documentID,
                    ownerUid: uid,
                    roastery: roastery,
                    grain: grain,
                    waterGrams: waterGrams,
                    coffeeGrams: coffeeGrams,
                    ratio: ratio,
                    temp: temp,
                    tool: tool,
                    field3: stepDictionaries,
                    localRecipeId: localRecipeId
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
                    userInfo: [NSLocalizedDescriptionKey: "Missing Firebase user.".localized()]
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

struct YourDataModelRes: Codable,Hashable,Identifiable {
 
    
    var id : String?
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
         return lhs.rostery == rhs.rostery &&
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
          case id
          case rostery
        case grain,waterGrams,coffeeGrams,ratio,temp,tool
        case field3
        case ownerUid
        case likeCount
        case searchKeywords
        case localRecipeId
          // ... map other properties to their corresponding keys
      }
}
struct StepTime: Codable,Hashable {
    let step: String?
    let time: TimeInterval?
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}



//{
//    @State private var elapsedTime: TimeInterval = 0
//    @State private var currentPhase = 0
//     @State   var timer: Timer?
//
//    var body: some View {
//        VStack {
//        
//
//            Text("Phase: \(phaseDescription(currentPhase))")
//                .font(.title)
//                .padding()
//
//            Text("Time: \(formatTime(elapsedTime))")
//                .font(.title)
//                .padding()
//
//            Button(action: {
//                startNextPhase()
//            }) {
//                if elapsedTime == 0 {
//                    Text("Start")
//                        .font(.title)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }else{
//                    Text("Next Phase")
//                        .font(.title)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//            }
//        }
//    }
//
//    func startNextPhase() {
//        if currentPhase < 4 {
//            currentPhase += 1
//            let phaseDuration: TimeInterval = 40 // Each phase lasts 40 seconds
//            let phaseStartTime = TimeInterval(currentPhase - 1) * phaseDuration
//            let phaseEndTime = TimeInterval(currentPhase) * phaseDuration
//
//            timer?.invalidate() // Stop the previous timer if it's running
//
//            withAnimation {
//                self.elapsedTime = phaseStartTime // Reset the elapsed time for the new phase
//            }
//
//            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//                withAnimation {
//                    self.elapsedTime += 1
//                }
//                if self.elapsedTime >= phaseEndTime {
//                    self.timer?.invalidate()
//                }
//            }
//        }
//    }
//
//
//
//    func phaseDescription(_ phase: Int) -> String {
//        switch phase {
//        case 1:
//            return "Blooming"
//        case 2:
//            return "first Drip"
//        case 3:
//            return "second Dirp"
//        case 4:
//            return "Third Drip"
//        default:
//            return "No Phase"
//        }
//    }
//
//    func formatTime(_ time: TimeInterval) -> String {
//        let seconds = Int(time)
//        let minutes = (seconds % 3600) / 60
//        let hours = seconds / 3600
//        return String(format: "%02d:%02d:%02d", hours, minutes, seconds % 60)
//    }
//}
