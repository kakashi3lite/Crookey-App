//
//  PantryService.swift
//  Crookey
//
//  Created by Claude Code
//  Copyright © 2025 Crookey. All rights reserved.
//

import Foundation
import OSLog

/// High-level service for pantry management
/// Wraps DatabaseService with business logic and validation
/// PRIVACY: All operations are 100% local, zero network calls
@MainActor
final class PantryService: ObservableObject {
    static let shared = PantryService()

    @Published private(set) var items: [PantryItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: DatabaseError?

    private let database: DatabaseService
    private let logger = Logger(subsystem: "com.crookey.app", category: "PantryService")

    init(database: DatabaseService = .shared) {
        self.database = database
    }

    // MARK: - Initialization

    /// Initialize service and load pantry data
    func initialize() async throws {
        logger.info("Initializing PantryService...")

        isLoading = true
        defer { isLoading = false }

        do {
            try await database.initialize()
            try await refreshItems()
            logger.info("✅ PantryService initialized with \(self.items.count) items")
        } catch {
            logger.error("❌ PantryService initialization failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Public Interface

    /// Add item to pantry with validation
    func addItem(_ item: PantryItem) async throws {
        logger.info("Adding item to pantry: \(item.name)")

        // Validation
        guard !item.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DatabaseError.invalidData("Item name cannot be empty")
        }

        guard item.quantity > 0 else {
            throw DatabaseError.invalidData("Quantity must be greater than 0")
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await database.insertPantryItem(item)
            try await refreshItems()
            logger.info("✅ Added item: \(item.name)")
        } catch {
            self.error = error as? DatabaseError
            logger.error("❌ Failed to add item: \(error.localizedDescription)")
            throw error
        }
    }

    /// Remove item from pantry
    func removeItem(id: UUID) async throws {
        logger.info("Removing item from pantry: \(id)")

        isLoading = true
        defer { isLoading = false }

        do {
            try await database.deletePantryItem(id: id)
            try await refreshItems()
            logger.info("✅ Removed item: \(id)")
        } catch {
            self.error = error as? DatabaseError
            logger.error("❌ Failed to remove item: \(error.localizedDescription)")
            throw error
        }
    }

    /// Remove multiple items (bulk delete)
    func removeItems(ids: [UUID]) async throws {
        logger.info("Removing \(ids.count) items from pantry")

        isLoading = true
        defer { isLoading = false }

        var errors: [Error] = []

        for id in ids {
            do {
                try await database.deletePantryItem(id: id)
            } catch {
                errors.append(error)
                logger.warning("Failed to remove item \(id): \(error.localizedDescription)")
            }
        }

        try await refreshItems()

        if !errors.isEmpty {
            logger.warning("⚠️ Bulk delete completed with \(errors.count) errors")
            throw DatabaseError.deleteFailed("\(errors.count) items failed to delete")
        }

        logger.info("✅ Removed \(ids.count) items")
    }

    /// Refresh pantry items from database
    func refreshItems() async throws {
        do {
            items = try await database.fetchAllPantryItems()
            logger.debug("Refreshed \(self.items.count) pantry items")
        } catch {
            self.error = error as? DatabaseError
            logger.error("❌ Failed to refresh items: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Query Methods

    /// Get items by category
    func items(in category: FoodCategory) -> [PantryItem] {
        items.filter { $0.category == category }
    }

    /// Get expired items
    var expiredItems: [PantryItem] {
        items.filter { $0.isExpired }
    }

    /// Get items expiring soon (within 3 days)
    var expiringSoonItems: [PantryItem] {
        items.filter { $0.isExpiringSoon }
    }

    /// Search items by name
    func searchItems(query: String) -> [PantryItem] {
        guard !query.isEmpty else { return items }

        let lowercaseQuery = query.lowercased()
        return items.filter { $0.name.lowercased().contains(lowercaseQuery) }
    }

    /// Get ingredients available for recipe generation
    /// Returns formatted string for LLM prompt
    func getAvailableIngredientsForRecipe() -> String {
        guard !items.isEmpty else {
            return "No ingredients available in pantry."
        }

        let ingredientsList = items
            .map { "\(Int($0.quantity)) \($0.unit.rawValue) \($0.name)" }
            .joined(separator: ", ")

        return ingredientsList
    }

    /// Get ingredients list as array for recipe context
    func getIngredientNames() -> [String] {
        items.map { $0.name }
    }

    // MARK: - Statistics

    var totalItems: Int {
        items.count
    }

    var itemsByCategory: [FoodCategory: Int] {
        Dictionary(grouping: items, by: \.category)
            .mapValues { $0.count }
    }

    var expirationAlertCount: Int {
        expiredItems.count + expiringSoonItems.count
    }

    // MARK: - Convenience Methods

    /// Quick add with defaults
    func quickAdd(
        name: String,
        category: FoodCategory,
        quantity: Double = 1,
        unit: MeasurementUnit = .pieces
    ) async throws {
        let item = PantryItem(
            name: name,
            category: category,
            quantity: quantity,
            unit: unit
        )
        try await addItem(item)
    }
}

// MARK: - Test Helpers

#if DEBUG
extension PantryService {
    /// Create test instance with in-memory database
    static func createTestInstance() async throws -> PantryService {
        let database = try await DatabaseService.createTestInstance()
        return PantryService(database: database)
    }

    /// Reset service for testing
    func resetForTesting() async throws {
        try await database.resetForTesting()
        try await refreshItems()
    }

    /// Populate with test data
    func populateTestData() async throws {
        let testItems = [
            PantryItem(
                name: "Chicken Breast",
                category: .meat,
                quantity: 2,
                unit: .pounds,
                expirationDate: Date().addingTimeInterval(5 * 24 * 60 * 60)
            ),
            PantryItem(
                name: "Mushrooms",
                category: .produce,
                quantity: 250,
                unit: .grams,
                expirationDate: Date().addingTimeInterval(3 * 24 * 60 * 60)
            ),
            PantryItem(
                name: "Onions",
                category: .produce,
                quantity: 3,
                unit: .pieces
            ),
            PantryItem(
                name: "Olive Oil",
                category: .condiments,
                quantity: 500,
                unit: .milliliters
            ),
            PantryItem(
                name: "Pasta",
                category: .grains,
                quantity: 1,
                unit: .kilograms
            ),
        ]

        for item in testItems {
            try await addItem(item)
        }
    }
}
#endif
