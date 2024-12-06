//
//  AdvancedSearchService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Foundation
import Combine

class AdvancedSearchService {
    static let shared = AdvancedSearchService()
    
    func searchRecipes(with filters: RecipeFilters) async throws -> [Recipe] {
        var queryItems = [
            URLQueryItem(name: "apiKey", value: AppConfig.API.spoonacularKey)
        ]
        
        // Add complex filters
        if let cuisines = filters.cuisines {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisines.joined(separator: ",")))
        }
        
        if let diets = filters.diets {
            queryItems.append(URLQueryItem(name: "diet", value: diets.joined(separator: ",")))
        }
        
        if let intolerances = filters.intolerances {
            queryItems.append(URLQueryItem(name: "intolerances", value: intolerances.joined(separator: ",")))
        }
        
        // Add nutritional filters
        if let maxCalories = filters.maxCalories {
            queryItems.append(URLQueryItem(name: "maxCalories", value: String(maxCalories)))
        }
        
        if let minProtein = filters.minProtein {
            queryItems.append(URLQueryItem(name: "minProtein", value: String(minProtein)))
        }
        
        // Add timing filters
        if let maxReadyTime = filters.maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: String(maxReadyTime)))
        }
        
        return try await NetworkManager.shared.fetch(.complexSearch(queryItems))
    }
}

struct RecipeFilters {
    var cuisines: [String]?
    var diets: [String]?
    var intolerances: [String]?
    var maxCalories: Int?
    var minProtein: Int?
    var maxReadyTime: Int?
    var ingredients: [String]?
    var excludeIngredients: [String]?
    var mealType: String?
}