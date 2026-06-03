//
//  RecepeiScreenApi.swift
//  Waznah
//
//  Created by Anas Hamad on 11/11/23.
//

import SwiftUI

struct RecepeiScreenApi: View {
    

    @ObservedObject var vm : FirestoreManager
    @State private var searchText = ""
    @State private var selectedMethod = "All"
    @State private var selectedSort: CloudRecipeSort = .newest
    @State private var showMineOnly = false
    
    private let methodFilters = ["All", "V60", "Chemex", "Espresso", "Cold Brew", "AeroPress"]
    
    var body: some View {
       
        NavigationView{
            ZStack{
                if displayedRecipes.isEmpty{
                    RecipeEmptyState(
                        systemImage: "cup.and.saucer.fill",
                        title: emptyTitle,
                        message: emptyMessage,
                        buttonTitle: vm.fetchedData.isEmpty ? nil : "Clear Filters".localized()
                    ) {
                        clearFilters()
                    }
                }
            VStack{
                cloudDiscoveryControls
                
                List{
                    ForEach(displayedRecipes){ rec in
                        RecepeiCardApiN(vm: vm, recepi: rec)
                    }
                    
                }
                .listStyle(.plain)
                //                        .onDelete(perform: deleteItem)
                
                
            }
            .opacity(displayedRecipes.isEmpty ? 0 : 1)
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .refreshable {
                refreshRecipes()
            }
            
             
           
            .navigationTitle("Community Recipes".localized())
            .onAppear{
                refreshRecipes()
               
            }
                if vm.isloading {
                    LoadingAlert()
                }
                
                
        }
    }
        }
      
    private func refreshRecipes() {
        vm.fetchDataFromFirestore { _ in
            if vm.fetchedData.isEmpty {
                vm.isloading = false
            }
        }
    }
    
    private var displayedRecipes: [YourDataModelRes] {
        var recipes = vm.fetchedData
        
        if selectedMethod != "All" {
            recipes = recipes.filter {
                ($0.tool ?? "").localizedCaseInsensitiveContains(selectedMethod)
            }
        }
        
        if showMineOnly {
            recipes = recipes.filter { $0.ownerUid == vm.currentUserID }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            recipes = recipes.filter { recipe in
                [
                    recipe.rostery,
                    recipe.grain,
                    recipe.waterGrams,
                    recipe.coffeeGrams,
                    recipe.ratio,
                    recipe.temp,
                    recipe.tool
                ]
                .compactMap { $0?.lowercased() }
                .joined(separator: " ")
                .contains(query)
                || (recipe.searchKeywords ?? []).contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        switch selectedSort {
        case .newest:
            return recipes
        case .mostLiked:
            return recipes.sorted { ($0.likeCount ?? 0) > ($1.likeCount ?? 0) }
        }
    }
    
    private var emptyTitle: String {
        vm.fetchedData.isEmpty ? "No community recipes".localized() : "No matching recipes".localized()
    }
    
    private var emptyMessage: String {
        vm.fetchedData.isEmpty
        ? "Community recipes from anonymous users will appear here.".localized()
        : "Try another search, method, or sorting filter.".localized()
    }
    
    private func clearFilters() {
        searchText = ""
        selectedMethod = "All"
        selectedSort = .newest
        showMineOnly = false
    }
    
    private var cloudDiscoveryControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search roastery, method, ratio".localized(), text: $searchText)
                    .textInputAutocapitalization(.never)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(methodFilters, id: \.self) { method in
                        CloudFilterChip(
                            title: method.localized(),
                            isSelected: selectedMethod == method
                        ) {
                            selectedMethod = method
                        }
                    }
                    
                    CloudFilterChip(
                        title: "My Shared".localized(),
                        isSelected: showMineOnly
                    ) {
                        showMineOnly.toggle()
                    }
                }
            }
            
            Picker("Sort".localized(), selection: $selectedSort) {
                ForEach(CloudRecipeSort.allCases) { sort in
                    Text(sort.title.localized()).tag(sort)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
    
  


#Preview {
    RecepeiScreenApi( vm: FirestoreManager())
}

enum CloudRecipeSort: String, CaseIterable, Identifiable {
    case newest
    case mostLiked
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .newest:
            return "Newest"
        case .mostLiked:
            return "Most liked"
        }
    }
}

struct CloudFilterChip: View {
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
                .foregroundColor(isSelected ? .white : Color(hex: "#86373E"))
                .background(isSelected ? Color(hex: "#86373E") : Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
    }
}


struct RecepeiCardApiN: View {
    
    @ObservedObject var vm: FirestoreManager
    let recepi : YourDataModelRes
    @State private var showSheet = false
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage = ""
    @State private var showDeleteError = false
    @State private var displayedLikeCount = 0
    @State private var displayedIsLiked = false
    @State private var isLikeAnimating = false
    @State private var isLikeRequestInFlight = false
   
    var body: some View {
        ZStack(alignment: .topTrailing) {
            PolishedRecipePreviewCard(
                roastery: recepi.rostery ?? "Unknown roastery".localized(),
                method: recepi.tool ?? "V60",
                coffee: recepi.coffeeGrams ?? "-",
                water: recepi.waterGrams ?? "-",
                ratio: recepi.ratio ?? "-",
                temperature: recepi.temp ?? "-",
                grain: recepi.grain ?? "",
                actionTitle: "View".localized(),
                showsDisclosure: false
            ) {
                showSheet.toggle()
            }
            
            VStack(spacing: 8) {
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
                
                if recepi.ownerUid == vm.currentUserID {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Color(hex: "#86373E"))
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.92))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.borderless)
                }
            }
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
            ApiRecepeiView(recepei: recepi)
        }
        .alert("Remove from Community?".localized(), isPresented: $showDeleteConfirmation) {
            Button("Delete".localized(), role: .destructive) {
                deleteCommunityRecipe()
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("This removes your recipe from the public Community feed.".localized())
        }
        .alert("Community action failed".localized(), isPresented: $showDeleteError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    private func deleteCommunityRecipe() {
        guard let id = recepi.id else {
            deleteErrorMessage = "Missing recipe id.".localized()
            showDeleteError = true
            return
        }
        
        vm.deleteRecipe(id: id) { error in
            DispatchQueue.main.async {
                if let error = error {
                    deleteErrorMessage = error.localizedDescription
                    showDeleteError = true
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
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
                    deleteErrorMessage = error.localizedDescription
                    showDeleteError = true
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
    let roastery: String
    let method: String
    let coffee: String
    let water: String
    let ratio: String
    let temperature: String
    let grain: String
    let actionTitle: String
    var showsDisclosure = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#F7EFE9"), Color(hex: "#EAD8CF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
                        
                        Label(method, systemImage: "mug.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "#86373E"))
                            .lineLimit(1)
                        
                        if !grain.isEmpty {
                            Text("\("Grind".localized()): \(grain)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if showsDisclosure {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundColor(Color(hex: "#86373E").opacity(0.7))
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
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemBackground), Color(hex: "#F7EFE9").opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(hex: "#86373E").opacity(0.12), radius: 18, x: 0, y: 10)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
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
        .background(Color(.secondarySystemBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct RecipeEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(Color(hex: "#86373E"))
                .padding()
                .background(Color(hex: "#86373E").opacity(0.12))
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
    }
}
