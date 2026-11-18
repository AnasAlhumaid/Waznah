//
//  WaznahClipApp.swift
//  WaznahClip — scan a coffee bag QR → see the crop's recipe → brew it.
//

import SwiftUI

@main
struct WaznahClipApp: App {
    @StateObject private var model = ClipRecipeModel()

    var body: some Scene {
        WindowGroup {
            ClipRootView()
                .environmentObject(model)
                .appLanguageLayout()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL { model.open(url: url) }
                }
        }
    }
}

@MainActor
final class ClipRecipeModel: ObservableObject {
    enum State {
        case waiting
        case loading
        case loaded(YourDataModelRes)
        case failed(String)
    }

    @Published private(set) var state: State = .waiting
    @Published var autoStartBrew = false
    private var currentID: String?

    init() {
        // Xcode: set the _XCAppClipURL environment variable in the scheme to test an invocation.
        if let raw = ProcessInfo.processInfo.environment["_XCAppClipURL"], let url = URL(string: raw) {
            open(url: url)
        }
    }

    func open(url: URL) {
        guard let invocation = ClipInvocation.recipeID(from: url) else {
            state = .failed("This code doesn't point to a Waznah recipe.".localized())
            return
        }
        autoStartBrew = invocation.startBrew
        load(id: invocation.id)
    }

    func retry() {
        if let currentID { load(id: currentID) }
    }

    private func load(id: String) {
        currentID = id
        state = .loading
        Task {
            do {
                state = .loaded(try await ClipRecipeService.shared.fetchRecipe(id: id))
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

struct ClipRootView: View {
    @EnvironmentObject private var model: ClipRecipeModel

    var body: some View {
        ZStack {
            WaznahScreenBackground()

            switch model.state {
            case .waiting:
                ClipMessageView(
                    systemImage: "qrcode.viewfinder",
                    title: "Scan a coffee bag".localized(),
                    message: "Scan the Waznah code on your coffee bag to see its recipe.".localized()
                )
            case .loading:
                ProgressView("Loading recipe...".localized())
            case .loaded(let recipe):
                RecipeQuickView(recipe: recipe, autoStartBrew: model.autoStartBrew)
            case .failed(let message):
                ClipMessageView(
                    systemImage: "exclamationmark.triangle.fill",
                    title: "Something went wrong".localized(),
                    message: message,
                    actionTitle: "Try Again".localized(),
                    action: model.retry
                )
            }
        }
    }
}

private struct ClipMessageView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(Color(hex: "#86373E"))
            Text(title).font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.headline)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Color(hex: "#86373E"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
}
