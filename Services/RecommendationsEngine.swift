//
//  RecommendationsEngine.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Foundation
import CoreML

class RecommendationsEngine {
    static let shared = RecommendationsEngine()
    
    private let userPreferences = UserPreferencesManager.shared
    private let persistenceManager = PersistenceManager.shared
    
    // User behavior weights
    private struct Weights {
        static let userPreference = 0.4
        static let previousInteractions = 0.3
        static let seasonality = 0.2
        static let timeOfDay = 0.1
    }
    
    func getRecommendations() async throws -> [Recipe] {
        // Fetch user preferences and history
        let preferences = userPreferences.getDietaryPreferences()
        let history = persistenceManager.fetchSavedRecipes()
        
        // Calculate contextual factors
        let seasonalIngredients = getSeasonalIngredients()
        let mealType = getCurrentMealType()
        
        // Build recommendation query
        let query = buildRecommendationQuery(
            preferences: preferences,
            history: history,
            seasonalIngredients: seasonalIngredients,
            mealType: mealType
        )
        
        // Fetch recommendations
        let recipes = try await RecipeService().fetchRecommendations(query: query)
        
        // Score and sort recipes
        return rankRecipes(recipes, based: on)
    }
    
    private func buildRecommendationQuery(
        preferences: UserPreferences,
        history: [Recipe],
        seasonalIngredients: [String],
        mealType: MealType
    ) -> RecommendationQuery {
        RecommendationQuery(
            cuisines: preferences.preferredCuisines,
            intolerances: preferences.allergies,
            dietaryRestrictions: preferences.dietaryRestrictions,
            mealType: mealType,
            includeIngredients: seasonalIngredients,
            excludeIngredients: preferences.dislikedIngredients,
            maxReadyTime: preferences.maxCookingTime
        )
    }
    
    private func rankRecipes(_ recipes: [Recipe], based history: [Recipe]) -> [Recipe] {
        recipes.map { recipe in
            var score = 0.0
            
            // Calculate preference score
            let preferenceScore = calculatePreferenceScore(for: recipe)
            score += preferenceScore * Weights.userPreference
            
            // Calculate historical interaction score
            let historyScore = calculateHistoryScore(for: recipe, history: history)
            score += historyScore * Weights.previousInteractions
            
            // Calculate seasonality score
            let seasonalityScore = calculateSeasonalityScore(for: recipe)
            score += seasonalityScore * Weights.seasonality
            
            // Calculate time relevance score
            let timeScore = calculateTimeScore(for: recipe)
            score += timeScore * Weights.timeOfDay
            
            return (recipe, score)
        }
        .sorted { $0.1 > $1.1 }
        .map { $0.0 }
    }
    
    private func getSeasonalIngredients() -> [String] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        
        // Return seasonal ingredients based on current month
        switch month {
        case 12...2: // Winter
            return ["potato", "carrot", "onion", "garlic", "squash"]
        case 3...5: // Spring
            return ["asparagus", "peas", "spinach", "lettuce", "strawberry"]
        case 6...8: // Summer
            return ["tomato", "cucumber", "corn", "zucchini", "berry"]
        case 9...11: // Fall
            return ["pumpkin", "apple", "mushroom", "cauliflower", "broccoli"]
        default:
            return []
        }
    }
    
    private func getCurrentMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6...10: return .breakfast
        case 11...14: return .lunch
        case 15...17: return .snack
        case 18...22: return .dinner
        default: return .snack
        }
    }
}