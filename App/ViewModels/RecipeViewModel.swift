//
//  RecipeViewModel.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Foundation
import Combine

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedRecipes: [Recipe] = []
    
    private let recipeService: RecipeService
    private let persistenceManager: PersistenceManager
    private var cancellables = Set<AnyCancellable>()
    
    init(recipeService: RecipeService = RecipeService(),
         persistenceManager: PersistenceManager = .shared) {
        self.recipeService = recipeService
        self.persistenceManager = persistenceManager
        loadSavedRecipes()
    }
    
    func fetchRandomRecipe() {
        isLoading = true
        
        Task {
            do {
                currentRecipe = try await recipeService.fetchRandomRecipe()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func saveRecipe(_ recipe: Recipe) {
        persistenceManager.saveRecipe(recipe)
        savedRecipes.append(recipe)
    }
    
    func removeRecipe(_ recipe: Recipe) {
        persistenceManager.removeRecipe(recipe.id)
        savedRecipes.removeAll { $0.id == recipe.id }
    }
    
    private func loadSavedRecipes() {
        savedRecipes = persistenceManager.fetchSavedRecipes()
    }
    
    func skipRecipe() {
        fetchRandomRecipe()
    }
}
