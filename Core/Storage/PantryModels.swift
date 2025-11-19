//
//  PantryModels.swift
//  Crookey
//
//  Created by Claude Code
//  Copyright © 2025 Crookey. All rights reserved.
//

import Foundation

// MARK: - Privacy-First Pantry Models
// All data structures designed for on-device SQLite storage
// NO cloud sync without explicit user consent via CloudKit E2EE

/// Represents a pantry item in the user's private inventory
/// Stored in UserPantry table - NEVER leaves device without consent
struct PantryItem: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let category: FoodCategory
    let quantity: Double
    let unit: MeasurementUnit
    let dateAdded: Date
    let expirationDate: Date?
    let notes: String?
    let barcode: String?

    init(
        id: UUID = UUID(),
        name: String,
        category: FoodCategory,
        quantity: Double,
        unit: MeasurementUnit,
        dateAdded: Date = Date(),
        expirationDate: Date? = nil,
        notes: String? = nil,
        barcode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.dateAdded = dateAdded
        self.expirationDate = expirationDate
        self.notes = notes
        self.barcode = barcode
    }

    /// Check if item is expired or expiring soon
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }

    var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let threeDays = Date().addingTimeInterval(3 * 24 * 60 * 60)
        return expirationDate < threeDays && !isExpired
    }
}

/// Food categories for pantry organization
enum FoodCategory: String, Codable, CaseIterable, Sendable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat & Poultry"
    case seafood = "Seafood"
    case grains = "Grains & Pasta"
    case canned = "Canned Goods"
    case frozen = "Frozen"
    case spices = "Spices & Seasonings"
    case baking = "Baking"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case condiments = "Condiments & Sauces"
    case other = "Other"
}

/// Standard measurement units
enum MeasurementUnit: String, Codable, CaseIterable, Sendable {
    case pieces = "pieces"
    case grams = "g"
    case kilograms = "kg"
    case pounds = "lbs"
    case ounces = "oz"
    case milliliters = "ml"
    case liters = "L"
    case cups = "cups"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
}

/// Product information from bundled database (Open Food Facts subset)
/// Read-only, pre-populated data - NO user PII
struct ProductInfo: Codable, Identifiable, Sendable {
    let id: UUID
    let barcode: String
    let name: String
    let brand: String?
    let category: FoodCategory
    let defaultShelfLifeDays: Int?

    init(
        id: UUID = UUID(),
        barcode: String,
        name: String,
        brand: String? = nil,
        category: FoodCategory,
        defaultShelfLifeDays: Int? = nil
    ) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.category = category
        self.defaultShelfLifeDays = defaultShelfLifeDays
    }
}

/// Recipe generated on-device by Foundation Models
/// Contains generation metadata for transparency
struct GeneratedRecipe: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let ingredients: [String]
    let instructions: [String]
    let servings: Int
    let estimatedTime: Int // minutes
    let generatedDate: Date
    let sourceIngredients: [String] // Pantry items used as context

    /// Privacy guarantee message shown to user
    var privacyMessage: String {
        "🔒 This recipe was generated 100% on your device. Your pantry data never left your phone."
    }

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [String],
        instructions: [String],
        servings: Int,
        estimatedTime: Int,
        generatedDate: Date = Date(),
        sourceIngredients: [String]
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.servings = servings
        self.estimatedTime = estimatedTime
        self.generatedDate = generatedDate
        self.sourceIngredients = sourceIngredients
    }
}

// MARK: - Database Errors

enum DatabaseError: Error, LocalizedError, Sendable {
    case initializationFailed(String)
    case migrationFailed(String)
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case notFound(String)
    case invalidData(String)
    case corruptedDatabase(String)

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Database initialization failed: \(message)"
        case .migrationFailed(let message):
            return "Database migration failed: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .insertFailed(let message):
            return "Insert operation failed: \(message)"
        case .updateFailed(let message):
            return "Update operation failed: \(message)"
        case .deleteFailed(let message):
            return "Delete operation failed: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .corruptedDatabase(let message):
            return "Database corrupted: \(message)"
        }
    }
}
