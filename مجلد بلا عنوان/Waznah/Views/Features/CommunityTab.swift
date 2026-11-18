//
//  CommunityTab.swift
//  Waznah — Community tab: View + ViewModel + subviews
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class CommunityRecipesViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedMethod = "All"
    @Published var selectedSort: CloudRecipeSort = .newest
    @Published var showMineOnly = false
    /// nil = all sources.
    @Published var selectedSource: RecipeSource?

    let firestore: FirestoreManager
    private var firestoreSubscription: AnyCancellable?

    private let methodFilters = ["All", "V60", "Chemex", "xBloom", "Espresso", "Cold Brew", "AeroPress"]
    var methodFilterOptions: [String] { methodFilters }

    init(firestore: FirestoreManager) {
        self.firestore = firestore
        firestoreSubscription = firestore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var displayedRecipes: [YourDataModelRes] {
        var recipes = firestore.fetchedData
        if selectedMethod != "All" {
            recipes = recipes.filter {
                ($0.tool ?? "").localizedCaseInsensitiveContains(selectedMethod)
            }
        }
        if showMineOnly {
            recipes = recipes.filter { $0.ownerUid == firestore.currentUserID }
        }
        if let selectedSource {
            recipes = recipes.filter { $0.recipeSource == selectedSource }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            recipes = recipes.filter { recipe in
                [recipe.rostery, recipe.crop, recipe.roaster, recipe.origin, recipe.process, recipe.tastingNotes,
                 recipe.grain, recipe.waterGrams, recipe.coffeeGrams, recipe.ratio, recipe.temp, recipe.tool]
                    .compactMap { $0?.lowercased() }
                    .joined(separator: " ")
                    .contains(query)
                    || (recipe.searchKeywords ?? []).contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        switch selectedSort {
        case .newest: return recipes
        case .mostLiked: return recipes.sorted { ($0.likeCount ?? 0) > ($1.likeCount ?? 0) }
        }
    }

    var emptyTitle: String {
        firestore.fetchedData.isEmpty ? "No community recipes".localized() : "No matching recipes".localized()
    }

    var emptyMessage: String {
        firestore.fetchedData.isEmpty
            ? "Community recipes from anonymous users will appear here.".localized()
            : "Try another search, method, or sorting filter.".localized()
    }

    func refresh() {
        firestore.fetchDataFromFirestore { _ in
            if self.firestore.fetchedData.isEmpty {
                self.firestore.isloading = false
            }
        }
    }

    /// Bundled roaster recipes, shown while the user isn't searching their own shares.
    var featuredRecipes: [FeaturedRecipe] {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !showMineOnly else { return [] }
        return FeaturedRecipes.all.filter { selectedMethod == "All" || $0.recipe.tool == selectedMethod }
    }

    func clearFilters() {
        searchText = ""
        selectedMethod = "All"
        selectedSort = .newest
        showMineOnly = false
        selectedSource = nil
    }
}

// MARK: - Community List

struct RecepeiScreenApi: View {
    @StateObject private var viewModel: CommunityRecipesViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(firestore: FirestoreManager) {
        _viewModel = StateObject(wrappedValue: CommunityRecipesViewModel(firestore: firestore))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Keep search & filters visible so an empty result can be fixed in place.
                if !viewModel.firestore.fetchedData.isEmpty {
                    discoveryControls
                }

                if viewModel.displayedRecipes.isEmpty {
                    if !viewModel.firestore.isloading {
                        RecipeEmptyState(
                            systemImage: viewModel.firestore.fetchedData.isEmpty ? "cup.and.saucer.fill" : "magnifyingglass",
                            title: viewModel.emptyTitle,
                            message: viewModel.emptyMessage,
                            buttonTitle: viewModel.firestore.fetchedData.isEmpty ? "Refresh".localized() : "Clear Filters".localized()
                        ) {
                            if viewModel.firestore.fetchedData.isEmpty {
                                viewModel.refresh()
                            } else {
                                viewModel.clearFilters()
                            }
                        }
                        .transition(.opacity)
                    } else {
                        Spacer()
                    }
                } else {
                    List {
                        if !viewModel.featuredRecipes.isEmpty {
                            FeaturedRecipesSection(recipes: viewModel.featuredRecipes, firestore: viewModel.firestore)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        ForEach(viewModel.displayedRecipes) { rec in
                            RecepeiCardApiN(vm: viewModel.firestore, recepi: rec)
                                // Set on the row itself; newer iOS ignores these when nested inside the card.
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        WaznahTabBarListSpacer()
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { viewModel.refresh() }
                }
            }
            .animation(.easeOut(duration: 0.2), value: viewModel.displayedRecipes.isEmpty)
            .waznahScreenBackdrop()
            .overlay {
                if viewModel.firestore.isloading {
                    LoadingAlert()
                }
            }
            .background(Color.clear)
            .navigationTitle("Community Recipes".localized())
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.refresh() }
        }
        .waznahAmbientNavigation()
    }

    private var discoveryControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search roastery, method, ratio".localized(), text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
            }
            .padding(12)
            .background(WaznahInsetSurfaceBackground())
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.methodFilterOptions, id: \.self) { method in
                        CloudFilterChip(
                            title: method.localized(),
                            isSelected: viewModel.selectedMethod == method
                        ) {
                            viewModel.selectedMethod = method
                        }
                    }
                    CloudFilterChip(
                        title: "My Shared".localized(),
                        isSelected: viewModel.showMineOnly
                    ) {
                        viewModel.showMineOnly.toggle()
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CloudFilterChip(title: "All Sources".localized(), isSelected: viewModel.selectedSource == nil) {
                        viewModel.selectedSource = nil
                    }
                    ForEach(RecipeSource.allCases) { source in
                        CloudFilterChip(title: source.title, isSelected: viewModel.selectedSource == source) {
                            viewModel.selectedSource = viewModel.selectedSource == source ? nil : source
                        }
                    }
                }
            }

            Picker("Sort".localized(), selection: $viewModel.selectedSort) {
                ForEach(CloudRecipeSort.allCases) { sort in
                    Text(sort.title.localized()).tag(sort)
                }
            }
            .pickerStyle(.segmented)
            .tint(WaznahBrandColors.accent(for: colorScheme))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

struct CloudFilterChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundColor(
                    isSelected ? .white : WaznahBrandColors.accent(for: colorScheme)
                )
                .background {
                    if isSelected {
                        WaznahBrandColors.accent(for: colorScheme)
                    } else {
                        WaznahChipSurfaceBackground()
                    }
                }
                .clipShape(Capsule())
        }
    }
}


struct RecepeiCardApiN: View {
    
    @ObservedObject var vm: FirestoreManager
    let recepi : YourDataModelRes
    @State private var showSheet = false
    @State private var actionErrorMessage = ""
    @State private var showActionError = false
    @State private var displayedLikeCount = 0
    @State private var displayedIsLiked = false
    @State private var isLikeAnimating = false
    @State private var isLikeRequestInFlight = false
   
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PolishedRecipePreviewCard(
                roastery: recepi.displayTitle,
                subtitle: recepi.displaySubtitle,
                source: recepi.recipeSource == .community ? nil : recepi.recipeSource,
                method: recepi.tool ?? "V60",
                coffee: recepi.coffeeGrams ?? "-",
                water: recepi.waterGrams ?? "-",
                ratio: recepi.ratio ?? "-",
                temperature: recepi.temp ?? "-",
                grain: recepi.grain ?? "",
                actionTitle: "View".localized(),
                showsDisclosure: false,
                titleTrailingClearance: 64
            ) {
                showSheet = true
            }
            
            Button {
                toggleLike()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: displayedIsLiked ? "heart.fill" : "heart")
                        .scaleEffect(isLikeAnimating ? 1.28 : 1)
                    
                    Text("\(displayedLikeCount)")
                }
                .font(.callout.weight(.bold))
                .foregroundColor(displayedIsLiked ? .white : Color(hex: "#86373E"))
                .padding(.horizontal, 14)
                .frame(minWidth: 58, minHeight: 48)
                .background(displayedIsLiked ? Color(hex: "#86373E") : Color.white.opacity(0.85))
                .clipShape(Capsule())
                .contentShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .scaleEffect(isLikeAnimating ? 1.08 : 1)
            }
            .buttonStyle(.borderless)
            .disabled(isLikeRequestInFlight)
            .padding(.trailing, 20)
            .padding(.top, 14)
        }
        .onAppear {
            syncDisplayedLikeState()
        }
        .onChange(of: recepi.likeCount ?? 0) { _ in
            syncDisplayedLikeState()
        }
        .onChange(of: recepi.isLikedByCurrentUser) { _ in
            syncDisplayedLikeState()
        }
        .sheet(isPresented: $showSheet) {
            ApiRecepeiView(recepei: recepi, firestore: vm)
        }
        .alert("Community action failed".localized(), isPresented: $showActionError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(actionErrorMessage)
        }
    }
    
    private func toggleLike() {
        guard !isLikeRequestInFlight else { return }
        
        let oldCount = displayedLikeCount
        let oldIsLiked = displayedIsLiked
        let newIsLiked = !oldIsLiked
        
        isLikeRequestInFlight = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
            displayedIsLiked = newIsLiked
            displayedLikeCount = newIsLiked ? oldCount + 1 : max(oldCount - 1, 0)
            isLikeAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                isLikeAnimating = false
            }
        }
        
        vm.toggleLike(recipe: recepi) { error in
            DispatchQueue.main.async {
                isLikeRequestInFlight = false
                
                if let error = error {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                        displayedLikeCount = oldCount
                        displayedIsLiked = oldIsLiked
                    }
                    actionErrorMessage = error.waznahUserFacingMessage
                    showActionError = true
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
        }
    }
    
    private func syncDisplayedLikeState() {
        guard !isLikeRequestInFlight else { return }
        displayedLikeCount = recepi.likeCount ?? 0
        displayedIsLiked = recepi.isLikedByCurrentUser
    }
}

struct RecipePreviewCard: View {
    let roastery: String
    let method: String
    let coffee: String
    let water: String
    let ratio: String
    let temperature: String
    let grain: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#86373E").opacity(0.12))
                        .frame(width: 76, height: 76)
                    
                    Image(methodImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(roastery.isEmpty ? "Untitled Recipe".localized() : roastery)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(method)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "#86373E"))
                        }
                        
                        Spacer()
                        
                        Label(actionTitle, systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        RecipeMetricPill(icon: "circle.hexagongrid", title: "Coffee".localized(), value: coffee, tint: Color(hex: "354449"))
                        RecipeMetricPill(icon: "drop.fill", title: "Water".localized(), value: water, tint: Color(hex: "648981"))
                        RecipeMetricPill(icon: "percent", title: "Ratio".localized(), value: ratio, tint: Color(hex: "BF8A6E"))
                        RecipeMetricPill(icon: "thermometer.medium", title: "Temp".localized(), value: temperature, tint: Color(hex: "8F7469"))
                    }
                    
                    if !grain.isEmpty {
                        Text("\("Grind".localized()): \(grain)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var methodImageName: String {
        method == "Cold Brew" ? "Clod Brew" : method
    }
}

struct RecipeMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(tint)
                .clipShape(Circle())
            
            Text("\(title):")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value.isEmpty ? "-" : value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PolishedRecipePreviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let roastery: String
    var subtitle: String? = nil
    var source: RecipeSource? = nil
    let method: String
    let coffee: String
    let water: String
    let ratio: String
    let temperature: String
    let grain: String
    let actionTitle: String
    var showsDisclosure = true
    /// Space kept clear at the title's trailing edge for an overlaid control (e.g. the like button).
    var titleTrailingClearance: CGFloat = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        WaznahRecipeThumbnailBackground()
                            .frame(width: 86, height: 86)
                        
                        Image(methodImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(roastery.isEmpty ? "Untitled Recipe".localized() : roastery)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            // Only the title line shares space with the overlaid like button.
                            .padding(.trailing, titleTrailingClearance)

                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.trailing, titleTrailingClearance)
                        }
                        
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "mug.fill")
                                Text(method)
                            }
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                                .lineLimit(1)
                                .fixedSize()
                            if let source { RecipeSourceBadge(source: source).fixedSize() }
                        }
                        
                        if !grain.isEmpty {
                            Text("\("Grind".localized()): \(grain)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    
                    Spacer(minLength: 0)
                    
                    if showsDisclosure {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(WaznahBrandColors.accent(for: colorScheme).opacity(0.7))
                    }
                }
                
                HStack(spacing: 8) {
                    PolishedRecipeMetric(icon: "circle.hexagongrid", title: "Coffee".localized(), value: coffee, tint: Color(hex: "354449"))
                    PolishedRecipeMetric(icon: "drop.fill", title: "Water".localized(), value: water, tint: Color(hex: "648981"))
                }
                
                HStack(spacing: 8) {
                    PolishedRecipeMetric(icon: "percent", title: "Ratio".localized(), value: ratio, tint: Color(hex: "BF8A6E"))
                    PolishedRecipeMetric(icon: "thermometer.medium", title: "Temp".localized(), value: temperature, tint: Color(hex: "8F7469"))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                WaznahRecipeCardBackground()
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    private var methodImageName: String {
        method == "Cold Brew" ? "Clod Brew" : method
    }
}

struct PolishedRecipeMetric: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(tint)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value.isEmpty ? "-" : value)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WaznahInsetSurfaceBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Roaster Picks

struct FeaturedRecipesSection: View {
    @Environment(\.colorScheme) private var colorScheme
    let recipes: [FeaturedRecipe]
    let firestore: FirestoreManager
    @State private var selected: FeaturedRecipe?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                Text("Roaster Picks".localized())
                    .font(.headline)
                Spacer()
                Text("\(recipes.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recipes) { featured in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selected = featured
                        } label: {
                            FeaturedRecipeCard(featured: featured)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
        }
        .sheet(item: $selected) { featured in
            let server = firestore.fetchedData.first { $0.id == featured.id }
            ApiRecepeiView(
                recepei: featured.recipe.applyingServerXBloomLinks(from: server),
                firestore: firestore
            )
        }
    }
}

private struct FeaturedRecipeCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let featured: FeaturedRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(featured.recipe.tool == "Cold Brew" ? "Clod Brew" : (featured.recipe.tool ?? "V60"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                Spacer()
                Text(featured.roaster.localized())
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WaznahCapsuleBadgeBackground())
                    .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                    .clipShape(Capsule())
            }

            Text(featured.crop.localized())
                .font(.headline)
                .lineLimit(1)
            Text(featured.origin.localized())
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(featured.tastingNotes.localized())
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text("\(featured.recipe.tool ?? "") · \(featured.recipe.coffeeGrams ?? "")g · \(featured.recipe.ratio ?? "") · \(featured.recipe.temp ?? "")°")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                .lineLimit(1)
        }
        .padding(14)
        .frame(width: 190, height: 178, alignment: .leading)
        .background { WaznahRecipeCardBackground() }
    }
}

struct RecipeEmptyState: View {
    @Environment(\.colorScheme) private var colorScheme
    let systemImage: String
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                .padding()
                .background(WaznahCapsuleBadgeBackground())
                .clipShape(Circle())
            
            Text(title)
                .font(.title3.bold())
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let buttonTitle, let action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#86373E"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.bottom, WaznahTabBarLayout.contentClearance / 2)
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

// MARK: - Cloud Detail

struct ApiRecepeiView: View {
    var recepei: YourDataModelRes
    var firestore: FirestoreManager

    @State private var showReportSheet = false
    @State private var showReportSuccess = false
    @State private var showReportError = false
    @State private var showAlreadyReported = false
    @State private var reportErrorMessage = ""
    @State private var reportReason = ""
    @State private var isReporting = false
    @State private var isCheckingReport = false

    private var canReport: Bool {
        guard let recipeId = recepei.id, !recipeId.isEmpty else { return false }
        guard let ownerUid = recepei.ownerUid else { return true }
        return ownerUid != firestore.currentUserID
    }

    var body: some View {
        RecipeDetailSheet(
            roastery: recepei.displayTitle,
            method: recepei.tool ?? "V60",
            coffee: recepei.coffeeGrams ?? "-",
            water: recepei.waterGrams ?? "-",
            ratio: recepei.ratio ?? "-",
            temperature: recepei.temp ?? "-",
            grind: recepei.grain ?? "-",
            notes: "",
            steps: recepei.field3 ?? [],
            sourceLabel: "Community Recipe".localized(),
            cloudRecipeId: recepei.id,
            recipe: recepei,
            onReport: canReport ? { beginReportFlow() } : nil
        )
        .sheet(isPresented: $showReportSheet) {
            RecipeReportSheet(
                recipeTitle: recepei.rostery ?? "Untitled Recipe".localized(),
                reason: $reportReason,
                isSubmitting: isReporting,
                onSubmit: submitReport,
                onCancel: { showReportSheet = false }
            )
            .waznahKeyboardDismissToolbar()
        }
        .overlay {
            if isCheckingReport {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Checking report...".localized())
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .alert("Report submitted".localized(), isPresented: $showReportSuccess) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Thank you. The developer will review this recipe.".localized())
        }
        .alert("Already reported".localized(), isPresented: $showAlreadyReported) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("You already reported this recipe. Each user can report a recipe only once.".localized())
        }
        .alert("Could not report recipe".localized(), isPresented: $showReportError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(reportErrorMessage)
        }
    }

    private func beginReportFlow() {
        guard let recipeId = recepei.id, !isCheckingReport else { return }

        isCheckingReport = true
        firestore.hasReportedRecipe(recipeId: recipeId) { result in
            isCheckingReport = false
            switch result {
            case .success(true):
                showAlreadyReported = true
            case .success(false):
                reportReason = ""
                showReportSheet = true
            case .failure(let error):
                if FirestoreManager.isPermissionDenied(error) {
                    // Old/mismatched rules may block the pre-check read; still allow reporting.
                    reportReason = ""
                    showReportSheet = true
                } else {
                    reportErrorMessage = error.waznahUserFacingMessage
                    showReportError = true
                }
            }
        }
    }

    private func submitReport() {
        guard let recipeId = recepei.id, !isReporting else { return }

        isReporting = true
        let title = recepei.rostery ?? "Untitled Recipe".localized()
        firestore.reportRecipe(id: recipeId, title: title, reason: reportReason) { error in
            isReporting = false
            if let error {
                if let reportError = error as? RecipeReportValidationError, reportError == .alreadyReported {
                    showReportSheet = false
                    showAlreadyReported = true
                    return
                }
                if FirestoreManager.isPermissionDenied(error) {
                    reportErrorMessage = "We couldn't send this report to our servers. Please try again later.".localized()
                } else {
                    reportErrorMessage = error.waznahUserFacingMessage
                }
                showReportError = true
            } else {
                showReportSheet = false
                showReportSuccess = true
            }
        }
    }
}

private struct RecipeReportSheet: View {
    @Environment(\.colorScheme) private var colorScheme

    let recipeTitle: String
    @Binding var reason: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void

    private var trimmedCount: Int {
        reason.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    private var canSubmit: Bool {
        trimmedCount >= 10 && trimmedCount <= 500 && !isSubmitting
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tell us why you are reporting this recipe.".localized())
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(recipeTitle)
                        .font(.headline.weight(.semibold))

                    TextEditor(text: $reason)
                        .frame(minHeight: 140)
                        .padding(10)
                        .background(WaznahInsetSurfaceBackground())
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )

                    HStack {
                        Text(
                            trimmedCount < 10
                                ? String(format: "At least %d characters required".localized(), max(0, 10 - trimmedCount))
                                : String(format: "%d / 500".localized(), trimmedCount)
                        )
                        .font(.caption)
                        .foregroundColor(trimmedCount < 10 ? Color(hex: "#86373E") : .secondary)
                        Spacer()
                    }

                    Text("Each account can report a recipe only once.".localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(WaznahScreenBackground())
            .navigationTitle("Report Recipe".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized(), action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit".localized(), action: onSubmit)
                        .fontWeight(.semibold)
                        .disabled(!canSubmit)
                }
            }
        }
        .navigationViewStyle(.stack)
        .waznahAmbientNavigation()
    }
}

struct RecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showBrewJourney = false
    
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
    var cloudRecipeId: String? = nil
    /// Cloud recipe, when available, for crop details and source badge.
    var recipe: YourDataModelRes? = nil
    /// Local recipes pass their links here. Cloud recipes use `recipe.xbloomLinks`.
    var xbloomLinks: XBloomRecipeLinks = .empty
    var cloudActionTitle: String? = nil
    var cloudActionSystemImage = "icloud.and.arrow.up.fill"
    var cloudActionTint = Color(hex: "#86373E")
    var isCloudActionLoading = false
    var onEdit: (() -> Void)? = nil
    var onReport: (() -> Void)? = nil
    var cloudAction: (() -> Void)? = nil
    
    private var methodImageName: String {
        method == "Cold Brew" ? "Clod Brew" : method
    }

    private var brewJourneyRecipe: BrewJourneyRecipe {
        BrewJourneyRecipe(
            title: roastery.isEmpty ? "Untitled Recipe".localized() : roastery,
            method: method,
            rawSteps: steps
        )
    }

    private var journeySteps: [BrewJourneyStep] {
        brewJourneyRecipe.steps
    }

    private var resolvedXBloomLinks: XBloomRecipeLinks {
        xbloomLinks.hasChoice ? xbloomLinks : (recipe?.xbloomLinks ?? .empty)
    }
    
    private var shareData: RecipeShareData {
        RecipeShareData(
            roastery: roastery,
            method: method,
            coffee: coffee,
            water: water,
            ratio: ratio,
            temperature: temperature,
            grind: grind,
            notes: notes,
            steps: steps,
            sourceLabel: sourceLabel,
            cloudRecipeId: cloudRecipeId
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    pageTopButtons
                    heroCard
                    startBrewJourneyButton
                    cloudActionButton
                    if resolvedXBloomLinks.hasChoice { OpenInXBloomButton(links: resolvedXBloomLinks) }
                    if let recipe, recipe.hasCropDetails { CropDetailsCard(recipe: recipe) }
                    metricsGrid
                    stepsSection
                    notesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background {
                WaznahScreenBackground()
            }
            .navigationTitle("Recipe Details".localized())
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .background(Color.clear)
        .waznahAmbientNavigation()
        .fullScreenCover(isPresented: $showBrewJourney) {
            BrewJourneyView(recipe: brewJourneyRecipe)
        }
    }
    
    private var pageTopButtons: some View {
        HStack {
            RecipePDFShareButton(shareData: shareData)
            if let onEdit {
                WaznahCircleIconButton(systemName: "pencil", diameter: 48) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onEdit()
                }
            }
            if let onReport {
                WaznahCircleIconButton(systemName: "flag.fill", diameter: 48) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onReport()
                }
            }
            Spacer()
            WaznahCircleIconButton(systemName: "xmark", diameter: 48) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }
        }
    }
    
    private var heroCard: some View {
        VStack(spacing: 14) {
            ZStack {
                WaznahHeroCircleBackground()
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

                if let subtitle = recipe?.displaySubtitle {
                    Text(subtitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 8) {
                    Label(method, systemImage: "mug.fill")
                    if let source = recipe?.recipeSource, source != .community {
                        RecipeSourceBadge(source: source)
                    } else {
                        Text("•")
                        Text(sourceLabel)
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .waznahGlassCard(cornerRadius: 32)
    }
    
    @ViewBuilder
    private var startBrewJourneyButton: some View {
        if !journeySteps.isEmpty {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showBrewJourney = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                    Text("Start Brew Journey".localized())
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#86373E"), Color(hex: "#BF8A6E")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(hex: "#86373E").opacity(0.2), radius: 14, x: 0, y: 8)
            }
        }
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

            if !journeySteps.isEmpty {
                Text("Zero your scale once. Pour to each target — no need to re-zero.".localized())
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            if journeySteps.isEmpty {
                Text("No brew steps added yet.".localized())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(WaznahInsetSurfaceBackground())
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(Array(journeySteps.enumerated()), id: \.element) { index, journeyStep in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "#86373E"))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(journeyStep.title.isEmpty ? "Pour".localized() : journeyStep.title)
                                .font(.headline)

                            Text(
                                String(
                                    format: "Pour to %@ ml".localized(),
                                    BrewJourneyBuilder.formatVolume(journeyStep.targetTotalML)
                                )
                            )
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(WaznahBrandColors.accent(for: colorScheme))
                            
                            HStack(spacing: 14) {
                                Label(
                                    String(
                                        format: "+%@ ml".localized(),
                                        BrewJourneyBuilder.formatVolume(journeyStep.pourAmountML)
                                    ),
                                    systemImage: "drop.fill"
                                )
                                if journeyStep.hasTimer {
                                    Label("\(journeyStep.durationSeconds) sec", systemImage: "timer")
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(WaznahInsetSurfaceBackground())
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
                    .background(WaznahInsetSurfaceBackground())
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
        .background(WaznahInsetSurfaceBackground())
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

//#Preview {
//    ApiRecepeiView()
//}


