//
//  Models.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//
import Foundation

// MARK: - Recipe Models
struct Recipe: Identifiable, Codable {
    let id: Int
    let title: String
    let readyInMinutes: Int
    let servings: Int
    let image: String
    let summary: String
    let instructions: String?
    let healthScore: Double?
    let diets: [String]?
    let ingredients: [Ingredient]?
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, title, readyInMinutes, servings, image, summary
        case instructions, healthScore, diets, ingredients
    }
}

struct Ingredient: Identifiable, Codable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    let image: String?
}

// MARK: - Food Analysis Models
struct FoodAnalysis: Identifiable {
    let id = UUID()
    let confidence: Double
    let classification: FoodClassification
    let nutritionalInfo: NutritionalInfo?
    let freshness: Freshness
}

enum FoodClassification {
    case fruit
    case vegetable
    case meat
    case dairy
    case grain
    case unknown
}

struct NutritionalInfo: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let vitamins: [String: Double]
}

enum Freshness {
    case fresh
    case moderate
    case spoiled
    case unknown
}

// MARK: - API Response Models
struct RecipeResponse: Codable {
    let recipes: [Recipe]
}

struct RecipeSearchResponse: Codable {
    let results: [Recipe]
    let offset: Int
    let number: Int
    let totalResults: Int
}
