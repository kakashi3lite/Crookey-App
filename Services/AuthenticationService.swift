//
//  AuthenticationService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Firebase
import FirebaseAuth
import FirebaseFirestore

class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        configureAuthStateChanges()
    }
    
    private func configureAuthStateChanges() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Create user profile in Firestore
            try await createUserProfile(userId: result.user.uid, email: email, name: name)
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func createUserProfile(userId: String, email: String, name: String) async throws {
        let userProfile = UserProfile(
            id: userId,
            email: email,
            name: name,
            createdAt: Date(),
            preferences: UserPreferences()
        )
        
        try await db.collection("users").document(userId).setData(userProfile.dictionary)
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
        } catch {
            self.error = error
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}