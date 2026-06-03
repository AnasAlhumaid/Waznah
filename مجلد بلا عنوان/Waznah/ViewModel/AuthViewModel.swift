//
//  AuthViewModel.swift
//  Waznah
//

import AuthenticationServices
import FirebaseAuth
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isChecking = true
    @Published var isSigningIn = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.isChecking = false
            }
        }
        
        Task {
            await authService.refreshCredentialStateIfNeeded()
            isAuthenticated = authService.isSignedIn
            isChecking = false
        }
    }
    
    deinit {
        if let authListenerHandle {
            Auth.auth().removeStateDidChangeListener(authListenerHandle)
        }
    }
    
    var providerLabel: String {
        guard let user = Auth.auth().currentUser else {
            return "—"
        }
        
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            return "Apple".localized()
        }
        
        return user.providerData.first?.providerID ?? "Unknown".localized()
    }
    
    var email: String? {
        Auth.auth().currentUser?.email
    }
    
    var shortUID: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            return "—"
        }
        
        if uid.count <= 12 {
            return uid
        }
        
        return "\(uid.prefix(6))…\(uid.suffix(4))"
    }
    
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        authService.configureAppleRequest(request)
    }
    
    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = error.localizedDescription
            isSigningIn = false
            
        case .success(let authorization):
            Task {
                await signIn(with: authorization)
            }
        }
    }
    
    private func signIn(with authorization: ASAuthorization) async {
        isSigningIn = true
        errorMessage = nil
        
        do {
            try await authService.handleAppleAuthorization(authorization)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSigningIn = false
    }
}
