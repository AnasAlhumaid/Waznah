//
//  RecipeQuickView.swift
//  Waznah + WaznahClip — short crop/recipe summary + "Start Brewing" into BrewJourneyView.
//  Shown for recipe links (QR on a coffee bag) in both the App Clip and the full app,
//  so the experience is the same whether or not Waznah is installed.
//

import StoreKit
import SwiftUI

struct RecipeQuickView: View {
    enum Context {
        case appClip
        case fullApp(onClose: () -> Void, onShowDetails: () -> Void)
    }

    @Environment(\.colorScheme) private var colorScheme
    let recipe: YourDataModelRes
    let autoStartBrew: Bool
    var context: Context = .appClip

    private var isAppClip: Bool {
        if case .appClip = context { return true }
        return false
    }

    @State private var showBrewJourney = false
    @State private var showAppOverlay = false

    private var accent: Color { WaznahBrandColors.accent(for: colorScheme) }
    private var method: String { recipe.tool ?? "V60" }
    private var steps: [StepsAndTimes] { recipe.field3 ?? [] }
    private var journey: BrewJourneyRecipe {
        BrewJourneyRecipe(
            title: recipe.rostery ?? "Untitled Recipe".localized(),
            method: method,
            rawSteps: steps
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                hero
                if let xbloom = recipe.xbloomShareURL { OpenInXBloomButton(url: xbloom) }
                if recipe.hasCropDetails { CropDetailsCard(recipe: recipe) }
                metrics
                if !journey.steps.isEmpty { stepsList }
                if isAppClip { getAppLink } else { fullRecipeLink }
            }
            .padding(.horizontal, 20)
            .padding(.top, isAppClip ? 24 : 8)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .top) { if !isAppClip { topBar } }
        .safeAreaInset(edge: .bottom) { startButton }
        .fullScreenCover(isPresented: $showBrewJourney, onDismiss: { if isAppClip { showAppOverlay = true } }) {
            BrewJourneyView(recipe: journey)
        }
        .appStoreOverlay(isPresented: $showAppOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
        .onAppear {
            if autoStartBrew, !journey.steps.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showBrewJourney = true }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                WaznahHeroCircleBackground().frame(width: 104, height: 104)
                Image(method == "Cold Brew" ? "Clod Brew" : method)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
            }
            Text(recipe.displayTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            if let subtitle = recipe.displaySubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 8) {
                Label(method.localized(), systemImage: "mug.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)
                if recipe.recipeSource != .community {
                    RecipeSourceBadge(source: recipe.recipeSource)
                }
            }
            if let grind = recipe.grain, !grind.isEmpty {
                Text("\("Grind".localized()): \(grind)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .waznahGlassCard(cornerRadius: 28)
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metric("circle.hexagongrid", "Coffee".localized(), "\(recipe.coffeeGrams ?? "-") g", Color(hex: "354449"))
            metric("drop.fill", "Water".localized(), "\(recipe.waterGrams ?? "-") ml", Color(hex: "648981"))
            metric("percent", "Ratio".localized(), recipe.ratio ?? "-", Color(hex: "BF8A6E"))
            metric("thermometer.medium", "Temp".localized(), "\(recipe.temp ?? "-")°", Color(hex: "8F7469"))
        }
    }

    private func metric(_ icon: String, _ title: String, _ value: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(tint)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.headline).monospacedDigit().lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(WaznahInsetSurfaceBackground())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Brew Steps".localized(), systemImage: "list.number")
                .font(.headline)
                .foregroundColor(accent)
            ForEach(Array(journey.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(hex: "#86373E"))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title.isEmpty ? "Pour".localized() : step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: "Pour to %@ ml".localized(), BrewJourneyBuilder.formatVolume(step.targetTotalML))
                             + (step.hasTimer ? " · \(step.durationSeconds) \("sec".localized())" : ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .waznahGlassCard(cornerRadius: 24)
    }

    /// Unobtrusive way to the full app; the App Store overlay itself only appears after brewing.
    private var getAppLink: some View {
        Button {
            showAppOverlay = true
        } label: {
            Label("Save recipes & more in the full Waznah app".localized(), systemImage: "arrow.down.app.fill")
                .font(.footnote.weight(.semibold))
                .foregroundColor(accent)
        }
        .padding(.top, 4)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                if case let .fullApp(onClose, _) = context { onClose() }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(accent)
                    .frame(width: 44, height: 44)
                    .background(WaznahChipSurfaceBackground())
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close".localized())
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    /// Full app only: jump to the regular recipe page (likes, share, report).
    private var fullRecipeLink: some View {
        Button {
            if case let .fullApp(_, onShowDetails) = context { onShowDetails() }
        } label: {
            Label("View full recipe".localized(), systemImage: "doc.text.magnifyingglass")
                .font(.footnote.weight(.semibold))
                .foregroundColor(accent)
        }
        .padding(.top, 4)
    }

    private var startButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showAppOverlay = false
            showBrewJourney = true
        } label: {
            Label("Start Brewing".localized(), systemImage: "play.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#86373E"))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(journey.steps.isEmpty)
        .opacity(journey.steps.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Shared crop/recipe presentation

/// Small pill telling where a recipe comes from (hidden for regular community recipes).
struct RecipeSourceBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    let source: RecipeSource

    var body: some View {
        let accent = WaznahBrandColors.accent(for: colorScheme)
        // Explicit icon + text: some iOS versions render Label icon-only inside buttons/cards.
        HStack(spacing: 4) {
            Image(systemName: source.systemImage)
            Text(source.title)
        }
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundColor(source == .official ? .white : accent)
            .background(source == .official ? accent : accent.opacity(0.14))
            .clipShape(Capsule())
    }
}

/// "About the crop": origin, process and tasting notes when the recipe has them.
struct CropDetailsCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let recipe: YourDataModelRes

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("About the Crop".localized(), systemImage: "leaf.fill")
                .font(.headline)
                .foregroundColor(WaznahBrandColors.accent(for: colorScheme))

            row("mappin.and.ellipse", "Origin".localized(), recipe.origin)
            row("drop.triangle.fill", "Process".localized(), recipe.process)
            row("sparkles", "Tasting Notes".localized(), recipe.tastingNotes)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .waznahGlassCard(cornerRadius: 24)
    }

    @ViewBuilder
    private func row(_ icon: String, _ title: String, _ value: String?) -> some View {
        if let value, !value.trimmingCharacters(in: .whitespaces).isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundColor(.secondary)
                    Text(value).font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

/// "Open in xBloom" — hands the recipe to the official xBloom app via its share link.
struct OpenInXBloomButton: View {
    @Environment(\.openURL) private var openURL
    let url: URL

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            openURL(url)
        } label: {
            HStack(spacing: 8) {
                Image("xBloom")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Open in xBloom".localized())
                    .font(.headline)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.forward.app")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .foregroundColor(.white)
            .background(Color(hex: "#2B2B2B"))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityHint("Opens this recipe in the xBloom app".localized())
    }
}
