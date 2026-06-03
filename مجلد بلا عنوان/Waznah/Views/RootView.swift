//
//  RootView.swift
//  Waznah
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isChecking {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    ProgressView()
                }
            } else if authViewModel.isAuthenticated {
                ContantView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        LocalRecipeSyncManager.shared.refresh(
                            in: CoreDataProvider.shared.viewContext
                        )
                    }
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: authViewModel.isChecking)
    }
}
