//
//  EditRecepie.swift
//  Waznah
//
//  Created by Anas Hamad on 11/11/23.
//

import SwiftUI
import FirebaseFirestore

struct StepsAndTimes : Hashable,Codable{
   
    var step: String
    var time: String
    var water: String
}

struct EditRecepie: View {
    @Environment(\.dismiss) private var dismiss
    @State var rostery = ""
    @State var grain = ""
    @State var water = ""
    @State var coffee = ""
    @State var tool = "V60"
    @State var ratio = ""
    @State var temp = ""
    @State var step = ""
    @State var time = ""
    @State var isloadind = false
    @State var isDone = false
    @State private var saveErrorMessage = ""
    @State private var showSaveError = false

    @ObservedObject var vm : FirestoreManager
//    @State private var stepsAndTimes: StepsAndTimes
    @State private var stepsAndTimes: [StepsAndTimes] = []
    let options = ["V60", "Chemex","Espresso", "Cold Brew","AeroPress"]
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FBF7F4"), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#86373E").opacity(0.08))
                                .frame(width: 92, height: 92)
                            
                            Image(tool == "Cold Brew" ? "Clod Brew" : tool)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 66, height: 66)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Add Community Recipe".localized())
                                .font(.largeTitle.weight(.bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Publish a recipe to the anonymous community feed.".localized())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(22)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color(hex: "#86373E").opacity(0.12), radius: 20, x: 0, y: 12)
                    )
                    .padding(.horizontal, 20)
                    
                    // Basic info card
                    VStack(spacing: 16) {
                        FloatingLabelTextField(
                            text: $rostery,
                            placeholder: "Example: Local roastery, Ethiopia Guji".localized(),
                            title: "Roastery".localized(),
                            image: ""
                        )
                        
                        FloatingLabelTextField(
                            text: $grain,
                            placeholder: "Example: Medium fine".localized(),
                            title: "Grind size".localized(),
                            image: ""
                        )
                        
                        // Better tool selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brew method".localized())
                                .font(.footnote.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(options, id: \.self) { option in
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            tool = option
                                        } label: {
                                            Text(option)
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 9)
                                                .background(
                                                    tool == option
                                                ? Color(hex: "#86373E")
                                                    : Color(.systemGray6)
                                                )
                                                .foregroundColor(
                                                    tool == option ? .white : .primary
                                                )
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            FloatingLabelTextField(
                                text: $coffee,
                                placeholder: "18 g",
                                title: "Coffee (g)".localized(),
                                image: ""
                            )
                            .keyboardType(.numberPad)
                            
                            FloatingLabelTextField(
                                text: $water,
                                placeholder: "270 ml",
                                title: "Water (ml)".localized(),
                                image: ""
                            )
                            .keyboardType(.numberPad)
                        }
                        
                        HStack(spacing: 12) {
                            FloatingLabelTextField(
                                text: $ratio,
                                placeholder: "Example: 1:15".localized(),
                                title: "Ratio".localized(),
                                image: ""
                            )
                            
                            FloatingLabelTextField(
                                text: $temp,
                                placeholder: "94°C",
                                title: "Temp (°C)".localized(),
                                image: ""
                            )
                            .keyboardType(.numberPad)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)
                    
                    // Steps card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Brew steps".localized())
                                .font(.headline)
                            Spacer()
                            Button {
                                addStepAndTime()
                            } label: {
                                Label("Add step".localized(), systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#86373E"))
                            }
                        }
                        .padding(.horizontal)
                        
                        if stepsAndTimes.isEmpty {
                            Text("Add your first pour step with water amount and time."
                                .localized())
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(stepsAndTimes.indices, id: \.self) { index in
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Step \(index + 1)")
                                            .font(.subheadline.bold())
                                        Spacer()
                                    }
                                    
                                    FloatingLabelTextField(
                                        text: $stepsAndTimes[index].step,
                                        placeholder: "Describe the pour".localized(),
                                        title: "Description".localized(),
                                        image: ""
                                    )
                                    
                                    HStack(spacing: 12) {
                                        FloatingLabelTextField(
                                            text: $stepsAndTimes[index].water,
                                            placeholder: "60",
                                            title: "Water (ml)".localized(),
                                            image: ""
                                        )
                                        .keyboardType(.numberPad)
                                        
                                        FloatingLabelTextField(
                                            text: $stepsAndTimes[index].time,
                                            placeholder: "30",
                                            title: "Time (sec)".localized(),
                                            image: ""
                                        )
                                        .keyboardType(.numberPad)
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)
                    
                    // Primary action button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let stepTimesAsDict = stepsAndTimes.map { stepTime -> [String: Any] in
                            [
                                "step": stepTime.step,
                                "time": stepTime.time,
                                "water": stepTime.water
                            ]
                        }
                        
                        let data = YourDataModel(
                            id: UUID(),
                            rostery: rostery,
                            grainSize: grain,
                            waterGrams: water,
                            coffeeGrams: coffee,
                            ratio: ratio,
                            temp: temp,
                            tool: tool,
                            field3: stepTimesAsDict
                        )
                        
                        createFirestoreDocument(data: data)
                    } label: {
                        HStack {
                            if isloadind {
                                ProgressView()
                                    .tint(.white)
                            }
                            
                            Text(isloadind ? "Saving...".localized() : "Share to Community".localized())
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color(hex: "#86373E") : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal)
                    }
                    .disabled(!canSubmit || isloadind)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 24)
                .onAppear {
                    vm.fetchDataFromFirestore { _ in }
                    if stepsAndTimes.isEmpty {
                        addStepAndTime()
                    }
                }
            }
            
            if isloadind {
                CustumAlertIsloading(
                    placeholedr: "Saving recipe...".localized(),
                    showAlert: $isloadind,
                    animte: true
                )
            }
            
            if isDone {
                CustumAlertDone(
                    placeholedr: "Saved!".localized(),
                    showAlert: $isDone
                )
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#86373E"))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 22)
                    .padding(.top, 14)
                }
                
                Spacer()
            }
        }
        .alert("Could not save recipe".localized(), isPresented: $showSaveError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    func addStepAndTime() {
        let newStepAndTime = StepsAndTimes( step: "", time: "", water: "")
              stepsAndTimes.append(newStepAndTime)
       }
    
    private var canSubmit: Bool {
        !rostery.trimmingCharacters(in: .whitespaces).isEmpty &&
        !grain.trimmingCharacters(in: .whitespaces).isEmpty &&
        !coffee.trimmingCharacters(in: .whitespaces).isEmpty &&
        !water.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ratio.trimmingCharacters(in: .whitespaces).isEmpty &&
        !temp.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    func createFirestoreDocument(data: YourDataModel) {
        
        self.isloadind = true
        
        vm.createRecipe(data: data) { error in
            DispatchQueue.main.async {
                self.isloadind = false
                
                if let error = error {
                    saveErrorMessage = firebaseHelpMessage(for: error)
                    showSaveError = true
                    return
                }
                
                self.isDone = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    dismiss()
                }
            }
        }
    }
    
    private func firebaseHelpMessage(for error: Error) -> String {
        let message = error.localizedDescription
        let nsError = error as NSError
        let firebaseName = nsError.userInfo["FIRAuthErrorUserInfoNameKey"] as? String
        let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        let response = nsError.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"]
        
        if message.localizedCaseInsensitiveContains("operation is not allowed") ||
            message.localizedCaseInsensitiveContains("admin restricted operation") {
            return "Sign in with Apple is disabled in Firebase. Open Firebase Console > Authentication > Sign-in method > Apple and enable it."
        }
        
        if message.localizedCaseInsensitiveContains("internal error") {
            return """
            Firebase Auth returned an internal error.
            
            Check these:
            1. Firebase Console > Authentication > Sign-in method > Apple is enabled.
            2. Apple Sign in capability is enabled for your app ID in Apple Developer.
            3. GoogleService-Info.plist belongs to this Firebase project and iOS bundle id.
            4. Firebase packages were resolved after adding FirebaseAuth.
            5. Enable Identity Toolkit API in Google Cloud for this Firebase project.
            
            Details: \(nsError.domain) (\(nsError.code))
            Name: \(firebaseName ?? "-")
            Underlying: \(underlyingError?.localizedDescription ?? "-")
            Response: \(String(describing: response ?? "-"))
            \(message)
            """
        }
        
        if message.localizedCaseInsensitiveContains("permission") {
            return "Firestore rules blocked this save. Deploy the new rules in firestore.rules or check the user is signed in."
        }
        
        return """
        \(message)
        
        Details: \(nsError.domain) (\(nsError.code))
        Name: \(firebaseName ?? "-")
        Underlying: \(underlyingError?.localizedDescription ?? "-")
        Response: \(String(describing: response ?? "-"))
        """
    }
}

#Preview {
    EditRecepie( vm: FirestoreManager())
}

struct PhaseData: Identifiable {
    let id = UUID()
    let description: String
    let phaseDuration: TimeInterval
}

struct YourDataModel: Identifiable{
    var id = UUID()
    var rostery: String
    var grainSize: String
    var waterGrams: String
    var coffeeGrams: String
    var ratio: String
    var temp: String
    var tool: String
    var field3:  [[String: Any]] // This is a map or dictionary
}

struct FloatingLabelTextField: View {
    @Binding  var text: String
   
    
    var placeholder: String
    var title: String
    var image : String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            Text(title)
                
            HStack(spacing: 10){
                if text.isEmpty && !image.isEmpty {
                    Image(image)
                }
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty, placeholder: {
                        HStack{
                            
                            Text(placeholder)
                                .foregroundColor(.gray)
                             
                        }
                    })
                .padding(.horizontal, 12)
            }
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14,style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.75))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14,style: .continuous)
                                .stroke(text.isEmpty ? Color.gray.opacity(0.25) : Color(hex: "#86373E").opacity(0.7), lineWidth: 1)
                        }
                )
               
            
        }
       
        .padding(.horizontal)
     
        
    }
}
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
