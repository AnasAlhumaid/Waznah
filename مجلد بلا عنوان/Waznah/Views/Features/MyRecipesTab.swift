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
    /// Coffee dose in grams (named `grind` for Core Data compatibility).
    // Ratio is recomputed on the next run loop: writing another @Published value synchronously
    // inside a TextField edit made the field drop/hide what was typed.
    @Published var grind = "" { didSet { scheduleRatioUpdate() } }
    @Published var temp = ""
    @Published var ratio = ""
    @Published var water = "" { didSet { scheduleRatioUpdate() } }
    @Published var more = ""
    @Published var brew = "V60"
    @Published var stepsAndTimes: [StepsAndTimes] = []
    @Published var isSaving = false
    @Published var showDetails = false

    let brewOptions = ["V60", "Chemex", "xBloom", "Espresso", "Cold Brew", "AeroPress"]

    /// Starting point per method so a new recipe is one tap away from savable.
    private struct MethodDefaults {
        let coffee: String
        let water: String
        let temp: String
    }

    private static let methodDefaults: [String: MethodDefaults] = [
        "V60": .init(coffee: "15", water: "250", temp: "93"),
        "Chemex": .init(coffee: "20", water: "320", temp: "94"),
        "xBloom": .init(coffee: "15", water: "240", temp: "93"),
        "Espresso": .init(coffee: "18", water: "36", temp: "93"),
        "Cold Brew": .init(coffee: "80", water: "800", temp: "20"),
        "AeroPress": .init(coffee: "15", water: "220", temp: "85")
    ]

    /// Fill coffee / water / temp from the method, without overwriting values the user typed.
    func selectMethod(_ method: String) {
        let previous = Self.methodDefaults[brew]
        brew = method
        guard let defaults = Self.methodDefaults[method] else { return }
        if grind.isEmpty || grind == previous?.coffee { grind = defaults.coffee }
        if water.isEmpty || water == previous?.water { water = defaults.water }
        if temp.isEmpty || temp == previous?.temp { temp = defaults.temp }
    }

    private func scheduleRatioUpdate() {
        DispatchQueue.main.async { [weak self] in self?.recomputeRatio() }
    }

    /// Ratio is derived from coffee and water, so the user never has to type it.
    private func recomputeRatio() {
        guard let coffee = Self.parseVolume(grind), coffee > 0,
              let waterML = Self.parseVolume(water), waterML > 0 else { return }
        ratio = "1:" + Self.formatVolume((waterML / coffee * 10).rounded() / 10)
    }

    /// Bloom (2× coffee) + three equal pours that add up exactly to the recipe water.
    func generateSteps() {
        guard let total = Self.parseVolume(water), total > 0 else { return }
        let coffee = Self.parseVolume(grind) ?? total / 16
        let bloom = min((coffee * 2).rounded(), total)
        let rest = total - bloom
        let pour = (rest / 3).rounded(.down)
        let last = rest - pour * 2

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        stepsAndTimes = [
            StepsAndTimes(step: "Bloom".localized(), time: "40", water: Self.formatVolume(bloom)),
            StepsAndTimes(step: "First pour".localized(), time: "30", water: Self.formatVolume(pour)),
            StepsAndTimes(step: "Second pour".localized(), time: "30", water: Self.formatVolume(pour)),
            StepsAndTimes(step: "Final pour".localized(), time: "45", water: Self.formatVolume(last))
        ].filter { (Self.parseVolume($0.water) ?? 0) > 0 }
        showDetails = true
    }

    /// Puts whatever water is left (or over) into the last step.
    func balanceLastStep() {
        guard let unassigned = unassignedWaterML, let lastIndex = stepsAndTimes.indices.last else { return }
        let current = stepWaterML(at: lastIndex)
        stepsAndTimes[lastIndex].water = Self.formatVolume(max(current + unassigned, 0))
    }

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
            showDetails = !stepsAndTimes.isEmpty || !more.isEmpty
        } else {
            selectMethod("V60")
            recomputeRatio()
        }
    }

    /// Only the essentials are required; ratio is computed and temp/steps/notes are optional.
    var canSubmit: Bool {
        !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Self.parseVolume(grind) ?? 0) > 0 &&
        (Self.parseVolume(water) ?? 0) > 0
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

        // Steps are optional: a recipe without pours is still valid.
        if stepWaters.isEmpty || stepsTotal == 0 {
            return nil
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
        let normalized = value.westernDigits
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
            cloudRecipeId: viewModel.currentCloudRecipeId,
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
                    VStack(spacing: 16) {
                        header
                        brewMethodCard
                        recipeInfoCard
                        detailsToggle
                        if formVM.showDetails {
                            stepsCard
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            notesCard
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        saveButton
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: formVM.showDetails)
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
        .alert(saveAlertTitle, isPresented: $showSaveError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                WaznahHeroCircleBackground().frame(width: 60, height: 60)
                Image(formVM.brewImageName).resizable().scaledToFit().frame(width: 42, height: 42)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(formVM.formTitle).font(.title2.weight(.bold))
                Text(formVM.formSubtitle)
                    .font(.footnote).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var recipeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocalRecipeTextField(title: "Roastery / Origin".localized(), text: $formVM.origin, placeholder: "Example: Ethiopia Guji".localized(), icon: "pin.fill")
            HStack(spacing: 12) {
                LocalRecipeTextField(title: "Coffee (g)".localized(), text: $formVM.grind, placeholder: "18", icon: "circle.hexagongrid", keyboardType: .decimalPad)
                LocalRecipeTextField(title: "Water (ml)".localized(), text: $formVM.water, placeholder: "270", icon: "drop.fill", keyboardType: .decimalPad)
            }
            HStack(spacing: 12) {
                LocalRecipeTextField(title: "Temp (°C)".localized(), text: $formVM.temp, placeholder: "94", icon: "thermometer.medium", keyboardType: .decimalPad)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ratio".localized())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                        Text(formVM.ratio.isEmpty ? "—" : formVM.ratio)
                            .monospacedDigit()
                        Spacer(minLength: 0)
                    }
                    .font(.headline)
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                    .padding(.horizontal, 12)
                    .frame(height: 48)
                    .background(WaznahBrandColors.accent(for: colorScheme).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    private var brewMethodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Brew Method".localized(), icon: "slider.horizontal.3")
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(formVM.brewOptions, id: \.self) { option in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) { formVM.selectMethod(option) }
                    } label: {
                        VStack(spacing: 6) {
                            Image(option == "Cold Brew" ? "Clod Brew" : option).resizable().scaledToFit().frame(width: 34, height: 34)
                            Text(option.localized()).font(.caption.weight(.semibold)).lineLimit(1)
                        }
                        .frame(width: 84)
                        .padding(.vertical, 12)
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
            .padding(.vertical, 2)
            }
        }
        .padding(16)
        .waznahGlassCard(cornerRadius: 24)
    }

    private var detailsToggle: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            formVM.showDetails.toggle()
        } label: {
            HStack {
                Label("Steps & notes (optional)".localized(), systemImage: "list.number")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !formVM.stepsAndTimes.isEmpty {
                    Text("\(formVM.stepsAndTimes.count)")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(WaznahBrandColors.accent(for: colorScheme).opacity(0.14))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(formVM.showDetails ? 180 : 0))
            }
            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
            .padding(16)
            .waznahGlassCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
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
                VStack(alignment: .leading, spacing: 10) {
                    Text("Skip this, or start from a ready pour plan and tweak it.".localized())
                        .font(.footnote).foregroundColor(.secondary)
                    Button { formVM.generateSteps() } label: {
                        Label("Use pour template".localized(), systemImage: "wand.and.stars")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(WaznahBrandColors.accent(for: colorScheme).opacity(0.14))
                            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(formVM.totalRecipeWaterML == nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(WaznahInsetSurfaceBackground())
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else if let unassigned = formVM.unassignedWaterML, abs(unassigned) > 0.05 {
                Button { formVM.balanceLastStep() } label: {
                    Label("Fix last step to match total".localized(), systemImage: "equal.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                }
            }
            VStack(spacing: 12) {
                ForEach(formVM.stepsAndTimes.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(String(format: "Step %d".localized(), index + 1)).font(.subheadline.weight(.bold))
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
