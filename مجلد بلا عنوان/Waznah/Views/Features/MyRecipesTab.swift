//
//  MyRecipesTab.swift
//  Waznah — My Recipes tab: View + ViewModel + subviews
//

import SwiftUI
import CoreData

// MARK: - ViewModels

@MainActor
final class MyRecipesListViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var deleteErrorMessage = ""
    @Published var showDeleteError = false

    let cloudManager: FirestoreManager
    private let syncManager = LocalRecipeSyncManager.shared

    init(cloudManager: FirestoreManager) {
        self.cloudManager = cloudManager
    }

    func refresh(in context: NSManagedObjectContext) {
        syncManager.refresh(in: context)
    }

    func deleteItems(at offsets: IndexSet, from recipes: [Recepie], in context: NSManagedObjectContext) {
        var cloudIdsToDelete: [String] = []

        for offset in offsets {
            guard recipes.indices.contains(offset) else { continue }
            let recipe = recipes[offset]
            let localId = recipe.stableLocalID.uuidString

            if let communityId = recipe.value(forKey: "cloudRecipeId") as? String, !communityId.isEmpty {
                cloudIdsToDelete.append(communityId)
            }

            context.delete(recipe)
            syncManager.deletePrivateRecipe(localId: localId)
        }

        do {
            try context.save()
        } catch {
            deleteErrorMessage = error.waznahUserFacingMessage
            showDeleteError = true
            return
        }

        for communityId in cloudIdsToDelete {
            cloudManager.deleteRecipe(id: communityId) { _ in }
        }
    }
}

@MainActor
final class LocalRecipeDetailViewModel: ObservableObject {
    @Published var isPublishing = false
    @Published var publishedCloudRecipeId: String?
    @Published var publishErrorMessage = ""
    @Published var showPublishError = false
    @Published var showPublishSuccess = false
    @Published var showShareCloudConfirmation = false
    @Published var showUnshareCloudConfirmation = false
    @Published var showUnshareSuccess = false

    let recepi: Recepie?
    let cloudManager: FirestoreManager

    init(recepi: Recepie?, cloudManager: FirestoreManager = FirestoreManager()) {
        self.recepi = recepi
        self.cloudManager = cloudManager
        publishedCloudRecipeId = Self.storedCloudRecipeId(for: recepi)
    }

    var isSharedToCommunity: Bool { currentCloudRecipeId != nil }

    var cloudActionTitle: String {
        isSharedToCommunity
            ? "Remove from Community".localized()
            : "Share to Community".localized()
    }

    var cloudActionSystemImage: String {
        isSharedToCommunity ? "icloud.slash.fill" : "icloud.and.arrow.up.fill"
    }

    var cloudActionTint: Color {
        isSharedToCommunity ? Color(hex: "#8F7469") : Color(hex: "#86373E")
    }

    var currentCloudRecipeId: String? {
        publishedCloudRecipeId ?? Self.storedCloudRecipeId(for: recepi)
    }

    static func storedCloudRecipeId(for recepi: Recepie?) -> String? {
        guard let value = recepi?.value(forKey: "cloudRecipeId") as? String, !value.isEmpty else { return nil }
        return value
    }

    var localSteps: [StepsAndTimes] {
        if let stepsData = recepi?.value(forKey: "stepsData") as? String,
           let data = stepsData.data(using: .utf8),
           let steps = try? JSONDecoder().decode([StepsAndTimes].self, from: data) {
            return steps
        }
        return legacyStepsFromNotes
    }

    var cleanNotes: String {
        let notes = recepi?.more ?? ""
        guard let range = notes.range(of: "Brew steps:") else { return notes }
        return String(notes[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var legacyStepsFromNotes: [StepsAndTimes] {
        let notes = recepi?.more ?? ""
        guard let range = notes.range(of: "Brew steps:") else { return [] }
        return notes[range.upperBound...]
            .split(separator: "\n")
            .compactMap { parseLegacyStep(String($0)) }
    }

    private func parseLegacyStep(_ line: String) -> StepsAndTimes? {
        let cleanedLine = line.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
        let parts = cleanedLine.components(separatedBy: " - ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !parts.isEmpty else { return nil }
        let step = parts[safe: 0] ?? ""
        let water = (parts[safe: 1] ?? "").replacingOccurrences(of: "ml", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let time = (parts[safe: 2] ?? "").replacingOccurrences(of: "sec", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return StepsAndTimes(step: step, time: time, water: water)
    }

    func publishToCloud(context: NSManagedObjectContext) {
        guard !isSharedToCommunity, let recepi else {
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
        ) { [weak self] result in
            guard let self else { return }
            self.isPublishing = false
            switch result {
            case .success(let cloudId):
                recepi.setValue(cloudId, forKey: "cloudRecipeId")
                try? context.save()
                LocalRecipeSyncManager.shared.syncLocalRecipe(recepi)
                self.publishedCloudRecipeId = cloudId
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.showPublishSuccess = true
            case .failure(let error):
                self.publishErrorMessage = error.waznahUserFacingMessage
                self.showPublishError = true
            }
        }
    }

    func unshareFromCommunity(context: NSManagedObjectContext) {
        guard isSharedToCommunity, let recepi, let cloudId = currentCloudRecipeId else {
            publishErrorMessage = "Missing local recipe.".localized()
            showPublishError = true
            return
        }

        isPublishing = true
        cloudManager.deleteRecipe(id: cloudId) { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isPublishing = false

                if let error {
                    self.publishErrorMessage = error.waznahUserFacingMessage
                    self.showPublishError = true
                    return
                }

                recepi.setValue(nil, forKey: "cloudRecipeId")
                do {
                    try context.save()
                } catch {
                    self.publishErrorMessage = error.waznahUserFacingMessage
                    self.showPublishError = true
                    return
                }

                LocalRecipeSyncManager.shared.syncLocalRecipe(recepi)
                self.publishedCloudRecipeId = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.showUnshareSuccess = true
            }
        }
    }
}

@MainActor
final class AddLocalRecipeViewModel: ObservableObject {
    @Published var origin = ""
    @Published var grind = ""
    @Published var temp = ""
    @Published var ratio = ""
    @Published var water = ""
    @Published var more = ""
    @Published var brew = "V60"
    @Published var stepsAndTimes: [StepsAndTimes] = []
    @Published var isSaving = false

    let brewOptions = ["V60", "Chemex", "Espresso", "Cold Brew", "AeroPress"]

    private let editingRecipe: Recepie?
    private let cloudManager: FirestoreManager

    var isEditing: Bool { editingRecipe != nil }

    var formTitle: String {
        isEditing ? "Edit Recipe".localized() : "Add Local Recipe".localized()
    }

    var formSubtitle: String {
        isEditing
            ? "Update your saved recipe. Shared recipes sync to Community.".localized()
            : "Save a recipe on this device for quick access.".localized()
    }

    var saveButtonTitle: String {
        isEditing ? "Save Changes".localized() : "Save Local Recipe".localized()
    }

    init(recepi: Recepie? = nil, cloudManager: FirestoreManager) {
        editingRecipe = recepi
        self.cloudManager = cloudManager

        if let recepi {
            origin = recepi.roastery ?? ""
            grind = recepi.grain ?? ""
            water = recepi.prepare ?? ""
            ratio = recepi.ratio ?? ""
            temp = recepi.temp ?? ""
            brew = recepi.tools ?? "V60"
            more = recepi.notesWithoutLegacySteps
            stepsAndTimes = recepi.decodedSteps
        }
    }

    var canSubmit: Bool {
        !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !grind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !water.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ratio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !temp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var brewImageName: String { brew == "Cold Brew" ? "Clod Brew" : brew }

    var totalRecipeWaterML: Double? {
        Self.parseVolume(water)
    }

    var unassignedWaterML: Double? {
        guard let total = totalRecipeWaterML else { return nil }
        let assigned = stepsAndTimes.indices.reduce(0.0) { partial, index in
            partial + stepWaterML(at: index)
        }
        return total - assigned
    }

    struct RemainingWaterDisplay {
        let text: String
        let isOver: Bool
    }

    func remainingWaterDisplay(afterStep index: Int) -> RemainingWaterDisplay? {
        guard let total = totalRecipeWaterML, stepsAndTimes.indices.contains(index) else { return nil }

        let used = (0...index).reduce(0.0) { partial, stepIndex in
            partial + stepWaterML(at: stepIndex)
        }
        let remaining = total - used

        if remaining >= -0.05 {
            return RemainingWaterDisplay(
                text: String(
                    format: "Remaining: %@ ml".localized(),
                    Self.formatVolume(max(0, remaining))
                ),
                isOver: false
            )
        }

        return RemainingWaterDisplay(
            text: String(
                format: "Over by %@ ml".localized(),
                Self.formatVolume(abs(remaining))
            ),
            isOver: true
        )
    }

    func formattedVolume(_ value: Double) -> String {
        Self.formatVolume(value)
    }

    func addStep() {
        stepsAndTimes.append(StepsAndTimes(step: "", time: "", water: ""))
    }

    /// Returns an alert message when recipe water is not fully divided across brew steps.
    func waterStepsValidationMessage() -> String? {
        guard let totalWater = Self.parseVolume(water), totalWater > 0 else { return nil }

        let stepWaters = validSteps.compactMap { Self.parseVolume($0.water) }
        let stepsTotal = stepWaters.reduce(0, +)
        let totalLabel = Self.formatVolume(totalWater)

        if stepWaters.isEmpty || stepsTotal == 0 {
            return String(
                format: "You entered %@ ml of water, but it is not divided across brew steps. Add steps that total %@ ml.".localized(),
                totalLabel,
                totalLabel
            )
        }

        if abs(stepsTotal - totalWater) > 0.05 {
            return String(
                format: "Your brew steps total %@ ml, but the recipe water is %@ ml. Divide all %@ ml across the steps.".localized(),
                Self.formatVolume(stepsTotal),
                totalLabel,
                totalLabel
            )
        }

        return nil
    }

    struct SaveOutcome {
        let didUpdateCommunity: Bool
    }

    func save(in context: NSManagedObjectContext, completion: @escaping (Result<SaveOutcome, Error>) -> Void) {
        if let validationMessage = waterStepsValidationMessage() {
            completion(.failure(RecipeFormValidationError(message: validationMessage)))
            return
        }

        let recipe = editingRecipe ?? Recepie(context: context)
        if editingRecipe == nil {
            recipe.id = UUID()
        }

        applyFormValues(to: recipe)

        do {
            try context.save()
        } catch {
            completion(.failure(error))
            return
        }

        LocalRecipeSyncManager.shared.syncLocalRecipe(recipe)

        guard let cloudId = recipe.cloudRecipeIdValue else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            completion(.success(SaveOutcome(didUpdateCommunity: false)))
            return
        }

        isSaving = true
        cloudManager.updateSharedRecipe(
            cloudRecipeId: cloudId,
            localRecipeId: recipe.stableLocalID.uuidString,
            roastery: origin,
            grain: grind,
            waterGrams: water,
            coffeeGrams: grind,
            ratio: ratio,
            temp: temp,
            tool: brew,
            steps: validSteps
        ) { [weak self] error in
            Task { @MainActor in
                self?.isSaving = false
                if let error {
                    completion(.failure(error))
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    completion(.success(SaveOutcome(didUpdateCommunity: true)))
                }
            }
        }
    }

    private func applyFormValues(to recipe: Recepie) {
        recipe.grain = grind
        recipe.prepare = water
        recipe.ratio = ratio
        recipe.roastery = origin
        recipe.temp = temp
        recipe.tools = brew
        recipe.more = more.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.setValue(encodedStepsData, forKey: "stepsData")
    }

    private var validSteps: [StepsAndTimes] {
        stepsAndTimes.filter {
            !$0.step.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.water.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var encodedStepsData: String? {
        guard !validSteps.isEmpty,
              let data = try? JSONEncoder().encode(validSteps) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func parseVolume(_ value: String) -> Double? {
        let normalized = value
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "ml", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    private static func formatVolume(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func stepWaterML(at index: Int) -> Double {
        guard stepsAndTimes.indices.contains(index) else { return 0 }
        return Self.parseVolume(stepsAndTimes[index].water) ?? 0
    }
}

struct RecipeFormValidationError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - My Recipes List

struct RecepeiScreen: View {
    @FetchRequest(fetchRequest: Recepie.all) private var recepisResults: FetchedResults<Recepie>
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: MyRecipesListViewModel

    init(cloudManager: FirestoreManager) {
        _viewModel = StateObject(wrappedValue: MyRecipesListViewModel(cloudManager: cloudManager))
    }

    var body: some View {
        NavigationStack {
            Group {
                if recepisResults.isEmpty {
                    RecipeEmptyState(
                        systemImage: "leaf.fill",
                        title: "No saved recipes".localized(),
                        message: "Save your favorite brew recipes here for quick access.".localized(),
                        buttonTitle: "Add Recipe".localized()
                    ) {
                        viewModel.showAddSheet = true
                    }
                } else {
                    List {
                        ForEach(recepisResults, id: \.self) { rec in
                            if rec.roastery != "" && rec.tools != "" {
                                RecepeiCard(recepi: rec, cloudManager: viewModel.cloudManager)
                            }
                        }
                        .onDelete { offsets in
                            viewModel.deleteItems(
                                at: offsets,
                                from: Array(recepisResults),
                                in: viewContext
                            )
                        }
                        WaznahTabBarListSpacer()
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .waznahScreenBackdrop()
            .navigationTitle("Recipes".localized())
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showAddSheet) {
                RecepieDetail(cloudManager: viewModel.cloudManager, showSheet: $viewModel.showAddSheet)
            }
            .alert("Could not delete recipe".localized(), isPresented: $viewModel.showDeleteError) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text(viewModel.deleteErrorMessage)
            }
            .onAppear { viewModel.refresh(in: viewContext) }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { viewModel.showAddSheet = true } label: {
                        Image(systemName: "plus.app").foregroundColor(Color("Color-2"))
                    }
                }
            }
        }
        .waznahAmbientNavigation()
    }
}

struct RecepeiCard: View {
    let recepi: Recepie
    let cloudManager: FirestoreManager
    @State private var showRecipe = false

    var body: some View {
        PolishedRecipePreviewCard(
            roastery: recepi.roastery ?? "Unknown roastery".localized(),
            method: recepi.tools ?? "V60",
            coffee: recepi.grain ?? "-",
            water: recepi.prepare ?? "-",
            ratio: recepi.ratio ?? "-",
            temperature: recepi.temp ?? "-",
            grain: "",
            actionTitle: "View".localized()
        ) {
            showRecipe = true
        }
        .sheet(isPresented: $showRecipe) {
            RecipeView(recepi: recepi, cloudManager: cloudManager)
        }
    }
}

// MARK: - Local Recipe Detail

struct RecipeView: View {
    @ObservedObject var recepi: Recepie
    @Environment(\.managedObjectContext) private var moc
    @StateObject private var viewModel: LocalRecipeDetailViewModel
    @State private var showEditSheet = false
    @State private var showEditSuccess = false
    @State private var didUpdateSharedOnEdit = false

    init(recepi: Recepie, cloudManager: FirestoreManager) {
        self.recepi = recepi
        _viewModel = StateObject(wrappedValue: LocalRecipeDetailViewModel(recepi: recepi, cloudManager: cloudManager))
    }

    var body: some View {
        RecipeDetailSheet(
            roastery: recepi.roastery ?? "Unknown roastery".localized(),
            method: recepi.tools ?? "V60",
            coffee: recepi.grain ?? "-",
            water: recepi.prepare ?? "-",
            ratio: recepi.ratio ?? "-",
            temperature: recepi.temp ?? "-",
            grind: recepi.grain ?? "-",
            notes: viewModel.cleanNotes,
            steps: viewModel.localSteps,
            sourceLabel: viewModel.isSharedToCommunity
                ? "Local Recipe • Shared to Community".localized()
                : "Local Recipe".localized(),
            cloudActionTitle: viewModel.cloudActionTitle,
            cloudActionSystemImage: viewModel.cloudActionSystemImage,
            cloudActionTint: viewModel.cloudActionTint,
            isCloudActionLoading: viewModel.isPublishing,
            onEdit: { showEditSheet = true },
            cloudAction: {
                if viewModel.isSharedToCommunity {
                    viewModel.showUnshareCloudConfirmation = true
                } else {
                    viewModel.showShareCloudConfirmation = true
                }
            }
        )
        .sheet(isPresented: $showEditSheet) {
            RecepieDetail(
                recepi: recepi,
                cloudManager: viewModel.cloudManager,
                showSheet: $showEditSheet
            ) { didUpdateCommunity in
                didUpdateSharedOnEdit = didUpdateCommunity
                showEditSuccess = true
            }
        }
        .alert("Recipe updated".localized(), isPresented: $showEditSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(
                didUpdateSharedOnEdit
                    ? "Your changes were saved and the shared Community recipe was updated.".localized()
                    : "Your local recipe was updated.".localized()
            )
        }
        .alert("Shared to Community".localized(), isPresented: $viewModel.showPublishSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Your local recipe is now public in Community Recipes.".localized())
        }
        .alert("Removed from Community".localized(), isPresented: $viewModel.showUnshareSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("This recipe is no longer visible in Community Recipes. You can share it again anytime.".localized())
        }
        .alert("Share to Community?".localized(), isPresented: $viewModel.showShareCloudConfirmation) {
            Button("Agree".localized()) { viewModel.publishToCloud(context: moc) }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This recipe will be public in Community Recipes. Other users can see it and like it.".localized())
        }
        .alert("Remove from Community?".localized(), isPresented: $viewModel.showUnshareCloudConfirmation) {
            Button("Remove".localized(), role: .destructive) {
                viewModel.unshareFromCommunity(context: moc)
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This removes your recipe from the public Community feed. Your local copy stays in My Recipes.".localized())
        }
        .alert("Community action failed".localized(), isPresented: $viewModel.showPublishError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(viewModel.publishErrorMessage)
        }
    }
}

// MARK: - Add Local Recipe

struct RecepieDetail: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var formVM: AddLocalRecipeViewModel
    @Binding var showSheet: Bool
    @State private var saveErrorMessage = ""
    @State private var showSaveError = false
    @State private var saveAlertTitle = "Could not save recipe".localized()

    var onSaved: ((Bool) -> Void)? = nil

    init(
        recepi: Recepie? = nil,
        cloudManager: FirestoreManager,
        showSheet: Binding<Bool>,
        onSaved: ((Bool) -> Void)? = nil
    ) {
        _showSheet = showSheet
        _formVM = StateObject(wrappedValue: AddLocalRecipeViewModel(recepi: recepi, cloudManager: cloudManager))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationView {
            ZStack {
                WaznahScreenBackground()
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
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .waznahKeyboardDismissToolbar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSheet = false } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .waznahAmbientNavigation()
        .onAppear {
            if formVM.stepsAndTimes.isEmpty { formVM.addStep() }
        }
        .alert(saveAlertTitle, isPresented: $showSaveError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                WaznahHeroCircleBackground().frame(width: 92, height: 92)
                Image(formVM.brewImageName).resizable().scaledToFit().frame(width: 66, height: 66)
            }
            VStack(spacing: 6) {
                Text(formVM.formTitle).font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
                Text(formVM.formSubtitle)
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .waznahGlassCard(cornerRadius: 32)
    }

    private var recipeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Recipe Info".localized(), icon: "mug.fill")
            LocalRecipeTextField(title: "Roastery / Origin".localized(), text: $formVM.origin, placeholder: "Example: Ethiopia Guji".localized(), icon: "pin.fill")
            HStack(spacing: 12) {
                LocalRecipeTextField(title: "Coffee (g)".localized(), text: $formVM.grind, placeholder: "18", icon: "circle.hexagongrid", keyboardType: .decimalPad)
                LocalRecipeTextField(title: "Water (ml)".localized(), text: $formVM.water, placeholder: "270", icon: "drop.fill", keyboardType: .decimalPad)
            }
            HStack(spacing: 12) {
                LocalRecipeTextField(title: "Ratio".localized(), text: $formVM.ratio, placeholder: "1:15", icon: "percent")
                LocalRecipeTextField(title: "Temp (°C)".localized(), text: $formVM.temp, placeholder: "94", icon: "thermometer.medium", keyboardType: .decimalPad)
            }
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    private var brewMethodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Brew Method".localized(), icon: "slider.horizontal.3")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(formVM.brewOptions, id: \.self) { option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        formVM.brew = option
                    } label: {
                        HStack(spacing: 8) {
                            Image(option == "Cold Brew" ? "Clod Brew" : option).resizable().scaledToFit().frame(width: 24, height: 24)
                            Text(option.localized()).font(.caption.weight(.semibold)).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background {
                            if formVM.brew == option {
                                WaznahBrandColors.accent(for: colorScheme).opacity(0.14)
                            } else {
                                WaznahChipSurfaceBackground()
                            }
                        }
                        .foregroundColor(formVM.brew == option ? WaznahBrandColors.accent(for: colorScheme) : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Notes".localized(), icon: "note.text")
            TextField("Optional tasting notes, method details...".localized(), text: $formVM.more, axis: .vertical)
                .lineLimit(3...6)
                .font(.body)
                .padding(14)
                .background(WaznahInsetSurfaceBackground())
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Brew Steps".localized(), icon: "list.number")
                Spacer()
                Button { formVM.addStep() } label: {
                    Label("Add step".localized(), systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                }
            }

            if let totalWater = formVM.totalRecipeWaterML {
                stepsWaterSummary(totalWater: totalWater)
            }

            if formVM.stepsAndTimes.isEmpty {
                Text("Add pour steps with water amount and time.".localized())
                    .font(.footnote).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(WaznahInsetSurfaceBackground())
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            VStack(spacing: 12) {
                ForEach(formVM.stepsAndTimes.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Step \(index + 1)").font(.subheadline.weight(.bold))
                            Spacer()
                            if let remaining = formVM.remainingWaterDisplay(afterStep: index) {
                                Text(remaining.text)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(
                                        remaining.isOver
                                            ? Color(hex: "#86373E")
                                            : WaznahBrandColors.accent(for: colorScheme)
                                    )
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        (remaining.isOver
                                            ? Color(hex: "#86373E")
                                            : WaznahBrandColors.accent(for: colorScheme)
                                        ).opacity(0.12)
                                    )
                                    .clipShape(Capsule())
                            }
                            Button { formVM.stepsAndTimes.remove(at: index) } label: {
                                Image(systemName: "trash").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        LocalRecipeTextField(title: "Description".localized(), text: $formVM.stepsAndTimes[index].step, placeholder: "Bloom / first pour".localized(), icon: "text.alignleft")
                        HStack(spacing: 12) {
                            LocalRecipeTextField(title: "Water (ml)".localized(), text: $formVM.stepsAndTimes[index].water, placeholder: "60", icon: "drop.fill", keyboardType: .decimalPad)
                            LocalRecipeTextField(title: "Time (sec)".localized(), text: $formVM.stepsAndTimes[index].time, placeholder: "30", icon: "timer", keyboardType: .numberPad)
                        }
                    }
                    .padding(14)
                    .background(WaznahInsetSurfaceBackground())
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    @ViewBuilder
    private func stepsWaterSummary(totalWater: Double) -> some View {
        let unassigned = formVM.unassignedWaterML ?? totalWater
        let isOver = unassigned < -0.05
        let displayValue = isOver ? abs(unassigned) : max(0, unassigned)

        HStack(spacing: 8) {
            Label(
                String(format: "Total: %@ ml".localized(), formVM.formattedVolume(totalWater)),
                systemImage: "drop.fill"
            )
            Text("•")
            Text(
                isOver
                    ? String(format: "Over by %@ ml".localized(), formVM.formattedVolume(displayValue))
                    : String(format: "Left to divide: %@ ml".localized(), formVM.formattedVolume(displayValue))
            )
            .foregroundColor(isOver ? Color(hex: "#86373E") : WaznahBrandColors.accent(for: colorScheme))
        }
        .font(.footnote.weight(.semibold))
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(WaznahInsetSurfaceBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var saveButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            formVM.save(in: viewContext) { result in
                switch result {
                case .success(let outcome):
                    onSaved?(outcome.didUpdateCommunity)
                    showSheet = false
                case .failure(let error):
                    if error is RecipeFormValidationError {
                        saveAlertTitle = "Water not divided in steps".localized()
                    } else {
                        saveAlertTitle = "Could not save recipe".localized()
                    }
                    saveErrorMessage = error.waznahUserFacingMessage
                    showSaveError = true
                }
            }
        } label: {
            HStack {
                if formVM.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: formVM.isEditing ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                }
                Text(formVM.isSaving ? "Saving...".localized() : formVM.saveButtonTitle).font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(formVM.canSubmit && !formVM.isSaving ? Color(hex: "#86373E") : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!formVM.canSubmit || formVM.isSaving)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline.weight(.bold))
            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
    }
}

struct LocalRecipeTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    private var usesNumericField: Bool {
        keyboardType == .decimalPad || keyboardType == .numberPad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption.weight(.bold)).foregroundColor(.secondary)
            Group {
                if usesNumericField {
                    WaznahNumericTextField(text: $text, placeholder: placeholder, keyboardType: keyboardType)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(WaznahInsetSurfaceBackground())
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
