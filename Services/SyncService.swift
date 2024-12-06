//
//  SyncService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Firebase
import FirebaseFirestore
import Combine

class SyncService: ObservableObject {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        setupRealtimeSync()
    }
    
    func syncUserData() async throws {
        // Sync recipes
        let recipes = PersistenceManager.shared.fetchSavedRecipes()
        try await syncRecipes(recipes)
        
        // Sync meal plans
        let mealPlans = try await fetchMealPlans()
        try await syncMealPlans(mealPlans)
        
        // Sync preferences
        let preferences = UserPreferencesManager.shared.getDietaryPreferences()
        try await syncPreferences(preferences)
    }
    
    private func setupRealtimeSync() {
        // Listen for remote changes
        db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() else { return }
                
                self.handleRemoteChanges(data)
            }
    }
    
    private func handleRemoteChanges(_ data: [String: Any]) {
        // Update local data based on remote changes
        if let recipes = data["recipes"] as? [[String: Any]] {
            updateLocalRecipes(recipes)
        }
        
        if let mealPlans = data["mealPlans"] as? [[String: Any]] {
            updateLocalMealPlans(mealPlans)
        }
    }
    
    private func syncRecipes(_ recipes: [Recipe]) async throws {
        let recipeData = recipes.map { $0.dictionary }
        try await db.collection("users").document(userId)
            .updateData(["recipes": recipeData])
    }
}