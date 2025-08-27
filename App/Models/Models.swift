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
struct FoodAnalysis: Identifiable, Codable {
    let id: UUID
    let confidence: Double
    let classification: FoodClassification
    let nutritionalInfo: NutritionalInfo?
    let freshness: Freshness
    let alternativeResults: [(identifier: String, confidence: Double)]
    let timestamp: Date
    let error: String?
    
    init(id: UUID = UUID(), confidence: Double, classification: FoodClassification, 
         nutritionalInfo: NutritionalInfo?, freshness: Freshness, 
         alternativeResults: [(identifier: String, confidence: Double)] = [],
         timestamp: Date = Date(), error: String? = nil) {
        self.id = id
        self.confidence = confidence
        self.classification = classification
        self.nutritionalInfo = nutritionalInfo
        self.freshness = freshness
        self.alternativeResults = alternativeResults
        self.timestamp = timestamp
        self.error = error
    }
    
    // Custom Codable implementation for tuples
    enum CodingKeys: String, CodingKey {
        case id, confidence, classification, nutritionalInfo, freshness, timestamp, error
        case alternativeResults
    }
    
    struct AlternativeResult: Codable {
        let identifier: String
        let confidence: Double
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        confidence = try container.decode(Double.self, forKey: .confidence)
        classification = try container.decode(FoodClassification.self, forKey: .classification)
        nutritionalInfo = try container.decodeIfPresent(NutritionalInfo.self, forKey: .nutritionalInfo)
        freshness = try container.decode(Freshness.self, forKey: .freshness)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        
        let alternativeResultStructs = try container.decode([AlternativeResult].self, forKey: .alternativeResults)
        alternativeResults = alternativeResultStructs.map { ($0.identifier, $0.confidence) }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(classification, forKey: .classification)
        try container.encodeIfPresent(nutritionalInfo, forKey: .nutritionalInfo)
        try container.encode(freshness, forKey: .freshness)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(error, forKey: .error)
        
        let alternativeResultStructs = alternativeResults.map { AlternativeResult(identifier: $0.identifier, confidence: $0.confidence) }
        try container.encode(alternativeResultStructs, forKey: .alternativeResults)
    }
}

enum FoodClassification: String, Codable, CaseIterable {
    case fruit
    case vegetable
    case meat
    case dairy
    case grain
    case unknown
    
    var emoji: String {
        switch self {
        case .fruit: return "🍎"
        case .vegetable: return "🥕"
        case .meat: return "🥩"
        case .dairy: return "🥛"
        case .grain: return "🌾"
        case .unknown: return "❓"
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

struct NutritionalInfo: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let vitamins: [String: Double]
}

enum Freshness: String, Codable, CaseIterable {
    case fresh
    case moderate
    case checkBeforeConsuming
    case questionable
    case spoiled
    case unknown
    
    var description: String {
        switch self {
        case .fresh: return "Fresh - Good to eat"
        case .moderate: return "Good - Consume soon"
        case .checkBeforeConsuming: return "Check before consuming"
        case .questionable: return "Quality questionable"
        case .spoiled: return "Spoiled - Do not consume"
        case .unknown: return "Unable to determine freshness"
        }
    }
    
    var emoji: String {
        switch self {
        case .fresh: return "✅"
        case .moderate: return "⚠️"
        case .checkBeforeConsuming: return "🔍"
        case .questionable: return "❗"
        case .spoiled: return "❌"
        case .unknown: return "❓"
        }
    }
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
