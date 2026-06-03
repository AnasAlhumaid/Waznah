//
//  AuthView.swift
//  Waznah
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                VStack(spacing: 14) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(Color(hex: "#86373E"))
                        .padding(24)
                        .background(Color(hex: "#86373E").opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("Waznah".localized())
                        .font(.largeTitle.weight(.bold))
                    
                    Text("Continue to save recipes and share with the community.".localized())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                Spacer()
                
                VStack(spacing: 14) {
                    SignInWithAppleButton(.continue) { request in
                        viewModel.prepareAppleRequest(request)
                    } onCompletion: { result in
                        viewModel.handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(viewModel.isSigningIn)
                    
                    if viewModel.isSigningIn {
                        ProgressView("Signing in...".localized())
                            .font(.footnote)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
