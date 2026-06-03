//
//  RecepieDetail.swift
//  Waznah
//
//  Created by Anas Hamad on 7/27/23.
//

import SwiftUI

struct RecepieDetail: View {
    @State var origin  = ""
    @State var grind  = ""
    @State var temp  = ""
    @State var ratio  = ""
    @State var water  = ""
    @State var more = ""
    @State var brew  = "V60"
    @State private var stepsAndTimes: [StepsAndTimes] = []
   
    
    @Environment(\.managedObjectContext) private var viewContext
    
    let options = ["V60", "Chemex","Espresso", "Cold Brew","AeroPress"]
    @Binding var showSheet :Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FBF7F4"), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        recipeInfoCard
                        brewMethodCard
                        stepsCard
                        notesCard
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSheet = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#86373E"))
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#86373E").opacity(0.08))
                    .frame(width: 92, height: 92)
                
                Image(brewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 66, height: 66)
            }
            
            VStack(spacing: 6) {
                Text("Add Local Recipe".localized())
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text("Save a recipe on this device for quick access.".localized())
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
    }
    
    private var recipeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Recipe Info".localized(), icon: "mug.fill")
            
            LocalRecipeTextField(
                title: "Roastery / Origin".localized(),
                text: $origin,
                placeholder: "Example: Ethiopia Guji".localized(),
                icon: "pin.fill"
            )
            
            HStack(spacing: 12) {
                LocalRecipeTextField(
                    title: "Coffee (g)".localized(),
                    text: $grind,
                    placeholder: "18",
                    icon: "circle.hexagongrid",
                    keyboardType: .decimalPad
                )
                
                LocalRecipeTextField(
                    title: "Water (ml)".localized(),
                    text: $water,
                    placeholder: "270",
                    icon: "drop.fill",
                    keyboardType: .decimalPad
                )
            }
            
            HStack(spacing: 12) {
                LocalRecipeTextField(
                    title: "Ratio".localized(),
                    text: $ratio,
                    placeholder: "1:15",
                    icon: "percent"
                )
                
                LocalRecipeTextField(
                    title: "Temp (°C)".localized(),
                    text: $temp,
                    placeholder: "94",
                    icon: "thermometer.medium",
                    keyboardType: .decimalPad
                )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var brewMethodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Brew Method".localized(), icon: "slider.horizontal.3")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        brew = option
                    } label: {
                        HStack(spacing: 8) {
                            Image(option == "Cold Brew" ? "Clod Brew" : option)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Text(option.localized())
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(brew == option ? Color(hex: "#86373E").opacity(0.14) : Color(.secondarySystemBackground).opacity(0.8))
                        .foregroundColor(brew == option ? Color(hex: "#86373E") : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Notes".localized(), icon: "note.text")
            
            TextField("Optional tasting notes, method details...".localized(), text: $more, axis: .vertical)
                .lineLimit(3...6)
                .font(.body)
                .padding(14)
                .background(Color(.secondarySystemBackground).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
    
    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Brew Steps".localized(), icon: "list.number")
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    addStep()
                } label: {
                    Label("Add step".localized(), systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color(hex: "#86373E"))
                }
            }
            
            if stepsAndTimes.isEmpty {
                Text("Add pour steps with water amount and time.".localized())
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color(.secondarySystemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            VStack(spacing: 12) {
                ForEach(stepsAndTimes.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Step \(index + 1)")
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Button {
                                stepsAndTimes.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        LocalRecipeTextField(
                            title: "Description".localized(),
                            text: $stepsAndTimes[index].step,
                            placeholder: "Bloom / first pour".localized(),
                            icon: "text.alignleft"
                        )
                        
                        HStack(spacing: 12) {
                            LocalRecipeTextField(
                                title: "Water (ml)".localized(),
                                text: $stepsAndTimes[index].water,
                                placeholder: "60",
                                icon: "drop.fill",
                                keyboardType: .decimalPad
                            )
                            
                            LocalRecipeTextField(
                                title: "Time (sec)".localized(),
                                text: $stepsAndTimes[index].time,
                                placeholder: "30",
                                icon: "timer",
                                keyboardType: .numberPad
                            )
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            if stepsAndTimes.isEmpty {
                addStep()
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            saveR()
        } label: {
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                Text("Save Local Recipe".localized())
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSubmit ? Color(hex: "#86373E") : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!canSubmit)
    }
    
    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundColor(Color(hex: "#86373E"))
    }
    
    private var canSubmit: Bool {
        !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !grind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !water.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ratio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !temp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var brewImageName: String {
        brew == "Cold Brew" ? "Clod Brew" : brew
    }
    
    private func addStep() {
        stepsAndTimes.append(StepsAndTimes(step: "", time: "", water: ""))
    }
    
    private var validSteps: [StepsAndTimes] {
        stepsAndTimes.filter {
            !$0.step.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.water.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private var encodedStepsData: String? {
        guard !validSteps.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(validSteps) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func saveR(){
        let recepie = Recepie(context: viewContext)
    
        recepie.id = UUID()
         recepie.grain = grind
         recepie.prepare = water
         recepie.ratio = ratio
         recepie.roastery = origin
         recepie.temp = temp
         recepie.tools = brew
        recepie.more = more.trimmingCharacters(in: .whitespacesAndNewlines)
        recepie.setValue(encodedStepsData, forKey: "stepsData")
        
        do {
            try recepie.save()
            LocalRecipeSyncManager.shared.syncLocalRecipe(recepie)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showSheet = false
        } catch {
            print(error)
        }
    }
    
}

//struct RecepieDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        RecepieDetail()
//    }
//}


struct CustomTextFieldC: View {
    @Binding var text: String
    var placeHolder : String
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeHolder)
                    .foregroundColor(Color.gray)
                   
            }
            TextField("", text: $text)
            
        }
      
    }
}

struct LocalRecipeTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(height: 50)
                .background(Color(.secondarySystemBackground).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
