//
//  AuthService.swift
//  Waznah
//

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Security

enum AuthServiceError: LocalizedError {
    case missingNonce
    case missingIdentityToken
    case missingAppleUserID
    case notSignedIn
    
    var errorDescription: String? {
        switch self {
        case .missingNonce:
            return "Missing Apple sign-in nonce."
        case .missingIdentityToken:
            return "Missing Apple identity token."
        case .missingAppleUserID:
            return "Missing Apple user identifier."
        case .notSignedIn:
            return "Please sign in with Apple to continue."
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    
    private let keychainAppleUserIDKey = "waznah.auth.appleUserID"
    private var currentNonce: String?
    private let db = Firestore.firestore()
    
    private init() {}
    
    var currentUID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isSignedIn: Bool {
        Auth.auth().currentUser != nil
    }
    
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleAppleAuthorization(_ authorization: ASAuthorization) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthServiceError.missingIdentityToken
        }
        
        guard let nonce = currentNonce else {
            throw AuthServiceError.missingNonce
        }
        
        guard let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthServiceError.missingIdentityToken
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        
        let authResult = try await Auth.auth().signIn(with: firebaseCredential)
        let uid = authResult.user.uid
        let appleUserID = appleCredential.user
        
        saveAppleUserID(appleUserID)
        try await upsertUserDocument(
            uid: uid,
            appleUserID: appleUserID,
            email: appleCredential.email ?? authResult.user.email
        )
        
        currentNonce = nil
    }
    
    func refreshCredentialStateIfNeeded() async {
        guard let appleUserID = loadAppleUserID() else { return }
        
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: appleUserID) { state, _ in
                if state == .revoked || state == .notFound {
                    try? Auth.auth().signOut()
                    self.clearAppleUserID()
                }
                continuation.resume()
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        clearAppleUserID()
    }
    
    private func upsertUserDocument(uid: String, appleUserID: String, email: String?) async throws {
        var payload: [String: Any] = [
            "uid": uid,
            "authProvider": "apple",
            "appleUserId": appleUserID,
            "isAnonymous": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let email, !email.isEmpty {
            payload["email"] = email
        }
        
        try await db.collection("users").document(uid).setData(payload, merge: true)
    }
    
    private func saveAppleUserID(_ value: String) {
        KeychainHelper.save(value, for: keychainAppleUserIDKey)
    }
    
    private func loadAppleUserID() -> String? {
        KeychainHelper.load(for: keychainAppleUserIDKey)
    }
    
    private func clearAppleUserID() {
        KeychainHelper.delete(for: keychainAppleUserIDKey)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        
        while remaining > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            
            randomBytes.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private enum KeychainHelper {
    static func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    static func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
