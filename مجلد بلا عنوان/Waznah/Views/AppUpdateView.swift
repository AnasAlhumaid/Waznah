//
//  AppUpdateView.swift
//  Waznah
//

import StoreKit
import SwiftUI

struct AppUpdateView: View {
    let info: AppUpdateInfo
    let currentVersion: String
    let onUpdate: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                Image(systemName: "arrow.down.app.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(Color(hex: "#86373E"))
                    .padding(28)
                    .background(Color(hex: "#86373E").opacity(0.1))
                    .clipShape(Circle())
                
                VStack(spacing: 10) {
                    Text(info.title)
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                    
                    Text(info.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Text(
                        String(
                            format: "Your version: %@ • Required: %@".localized(),
                            currentVersion,
                            info.latestVersion
                        )
                    )
                    .font(.footnote)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onUpdate) {
                    Text("Update Now".localized())
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#86373E"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct AppLaunchView: View {
    @StateObject private var updateViewModel = AppUpdateViewModel()
    @StateObject private var deepLinkRouter = WaznahDeepLinkRouter.shared
    @StateObject private var reviewCoordinator = AppReviewCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    
    private var updateInfo: AppUpdateInfo? {
        switch updateViewModel.updateKind {
        case .none:
            return nil
        case .optional(let info), .required(let info):
            return info
        }
    }
    
    private var mustUpdate: Bool {
        updateInfo != nil
    }
    
    var body: some View {
        ZStack {
            ContantView()
                .disabled(mustUpdate)
            
            if updateViewModel.phase == .checking {
                Color(.systemBackground)
                    .ignoresSafeArea()
                ProgressView("Checking for updates...".localized())
            }
            
            if let info = updateInfo {
                AppUpdateView(
                    info: info,
                    currentVersion: updateViewModel.currentVersion,
                    onUpdate: { updateViewModel.openAppStore(urlString: info.appStoreURL) }
                )
                .transition(.opacity)
            }
        }
        .appLanguageLayout()
        .environmentObject(deepLinkRouter)
        .onOpenURL { url in
            deepLinkRouter.handle(url: url)
        }
        // Camera QR scans of App Clip URLs arrive as a browsing-web activity, not via onOpenURL.
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            if let url = activity.webpageURL { deepLinkRouter.handle(url: url) }
        }
        .task {
            await updateViewModel.checkForUpdate()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            reviewCoordinator.noteBecameActive()
            Task {
                await updateViewModel.checkForUpdate()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: updateViewModel.updateKind)
        .animation(.easeInOut(duration: 0.2), value: updateViewModel.phase)
        .onAppear {
            reviewCoordinator.noteBecameActive()
            reviewCoordinator.setLaunchGateVisible(updateViewModel.phase == .checking)
            reviewCoordinator.setUpdateWallVisible(mustUpdate)
        }
        .onChange(of: updateViewModel.phase) { phase in
            reviewCoordinator.setLaunchGateVisible(phase == .checking)
        }
        .onChange(of: mustUpdate) { blocked in
            reviewCoordinator.setUpdateWallVisible(blocked)
        }
        .onChange(of: reviewCoordinator.nativeReviewRequestID) { _ in
            guard reviewCoordinator.nativeReviewRequestID > 0 else { return }
            requestReview()
        }
        .sheet(isPresented: $reviewCoordinator.isPresented) {
            RateWaznahSheet(source: reviewCoordinator.presentationSource)
                .waznahReviewSheetChrome()
                .waznahTimeBasedColorScheme()
                .appLanguageLayout()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
