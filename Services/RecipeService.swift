//
//  RecipeService.swift
//  Crookey
//
//  Created by Claude Code
//  Copyright © 2025 Crookey. All rights reserved.
//

import Foundation
import OSLog

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device recipe generation using Apple Foundation Models
/// PRIVACY GUARANTEE: All AI inference happens locally, zero network calls
/// This service never transmits pantry data to any server
@available(iOS 18.2, macOS 15.2, *)
actor RecipeService {
    static let shared = RecipeService()

    private let logger = Logger(subsystem: "com.crookey.app", category: "RecipeService")
    private var session: Any? // LMSession reference (type-erased for pre-iOS 18.2 compatibility)

    // MARK: - Initialization

    private init() {
        logger.info("RecipeService initialized")
    }

    // MARK: - Recipe Generation

    /// Generate recipe from pantry ingredients using on-device AI
    /// - Parameters:
    ///   - ingredients: Available pantry items
    ///   - preferences: Optional dietary preferences
    /// - Returns: Generated recipe with privacy metadata
    func generateRecipe(
        from ingredients: [String],
        preferences: RecipePreferences = .default
    ) async throws -> GeneratedRecipe {
        logger.info("🧠 Generating recipe on-device from \(ingredients.count) ingredients")

        guard !ingredients.isEmpty else {
            throw RecipeError.noIngredients
        }

        #if canImport(FoundationModels)
        // Ensure Foundation Models is available
        guard #available(iOS 18.2, macOS 15.2, *) else {
            throw RecipeError.modelNotAvailable("Foundation Models requires iOS 18.2+")
        }

        do {
            // Initialize session if needed
            if session == nil {
                session = try await initializeSession()
            }

            // Build contextual prompt
            let prompt = buildRecipePrompt(ingredients: ingredients, preferences: preferences)

            logger.info("📝 Prompt built: \(prompt.prefix(100))...")

            // Generate recipe using on-device model
            let generatedText = try await generateText(prompt: prompt)

            // Parse response into structured recipe
            let recipe = try parseRecipeFromText(generatedText, sourceIngredients: ingredients)

            logger.info("✅ Recipe generated on-device: \(recipe.title)")
            return recipe

        } catch {
            logger.error("❌ Recipe generation failed: \(error.localizedDescription)")
            throw RecipeError.generationFailed(error.localizedDescription)
        }
        #else
        // Fallback for development/testing without Foundation Models
        logger.warning("⚠️ Foundation Models not available, returning mock recipe")
        return createMockRecipe(from: ingredients, preferences: preferences)
        #endif
    }

    // MARK: - Foundation Models Integration

    #if canImport(FoundationModels)
    @available(iOS 18.2, macOS 15.2, *)
    private func initializeSession() async throws -> LMSession {
        logger.info("Initializing Foundation Models session...")

        // Create session with on-device model
        let session = try LMSession()

        logger.info("✅ Foundation Models session initialized")
        return session
    }

    @available(iOS 18.2, macOS 15.2, *)
    private func generateText(prompt: String) async throws -> String {
        guard let session = session as? LMSession else {
            throw RecipeError.modelNotAvailable("Session not initialized")
        }

        // Generate response using on-device model
        let response = try await session.generate(prompt: prompt)

        logger.debug("Generated \(response.count) characters")
        return response
    }
    #endif

    // MARK: - Prompt Engineering

    /// Build contextual prompt for recipe generation
    /// This is where the "gourmet intelligence" lives - the prompt builder
    private func buildRecipePrompt(
        ingredients: [String],
        preferences: RecipePreferences
    ) -> String {
        let ingredientsList = ingredients.joined(separator: ", ")

        // Base system message
        var prompt = """
        You are an expert chef creating recipes from available ingredients.

        AVAILABLE INGREDIENTS: \(ingredientsList)

        REQUIREMENTS:
        - Use ONLY the available ingredients (you may suggest small amounts of common pantry staples like salt, pepper, oil)
        - Create a practical, achievable recipe
        - Provide clear, numbered instructions
        - Include serving size and estimated cooking time
        """

        // Add dietary preferences
        if !preferences.dietaryRestrictions.isEmpty {
            let restrictions = preferences.dietaryRestrictions.joined(separator: ", ")
            prompt += "\n- DIETARY RESTRICTIONS: \(restrictions)"
        }

        // Add difficulty preference
        if let difficulty = preferences.difficulty {
            prompt += "\n- COMPLEXITY: \(difficulty.rawValue)"
        }

        // Add time constraint
        if let maxTime = preferences.maxCookingTimeMinutes {
            prompt += "\n- MAX COOKING TIME: \(maxTime) minutes"
        }

        // Format instruction
        prompt += """


        FORMAT YOUR RESPONSE AS:
        TITLE: [Recipe Name]
        SERVINGS: [Number]
        TIME: [Minutes]
        INGREDIENTS:
        - [ingredient with amount]
        - [ingredient with amount]
        INSTRUCTIONS:
        1. [First step]
        2. [Second step]
        ...

        Generate the recipe now:
        """

        return prompt
    }

    // MARK: - Response Parsing

    /// Parse generated text into structured recipe
    private func parseRecipeFromText(
        _ text: String,
        sourceIngredients: [String]
    ) throws -> GeneratedRecipe {
        logger.debug("Parsing recipe from generated text")

        // Split into sections
        let lines = text.components(separatedBy: .newlines)

        var title = "Generated Recipe"
        var servings = 2
        var estimatedTime = 30
        var ingredients: [String] = []
        var instructions: [String] = []

        var currentSection = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Parse title
            if trimmed.uppercased().hasPrefix("TITLE:") {
                title = trimmed.replacingOccurrences(of: "TITLE:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                continue
            }

            // Parse servings
            if trimmed.uppercased().hasPrefix("SERVINGS:") {
                let servingsText = trimmed.replacingOccurrences(of: "SERVINGS:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                servings = Int(servingsText.components(separatedBy: .whitespaces).first ?? "2") ?? 2
                continue
            }

            // Parse time
            if trimmed.uppercased().hasPrefix("TIME:") {
                let timeText = trimmed.replacingOccurrences(of: "TIME:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                estimatedTime = Int(timeText.components(separatedBy: .whitespaces).first ?? "30") ?? 30
                continue
            }

            // Section headers
            if trimmed.uppercased().contains("INGREDIENTS:") {
                currentSection = "ingredients"
                continue
            }

            if trimmed.uppercased().contains("INSTRUCTIONS:") {
                currentSection = "instructions"
                continue
            }

            // Parse ingredients
            if currentSection == "ingredients" && (trimmed.hasPrefix("-") || trimmed.hasPrefix("•")) {
                let ingredient = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                ingredients.append(ingredient)
            }

            // Parse instructions
            if currentSection == "instructions" {
                // Remove numbering (1., 2., etc.)
                let instruction = trimmed.replacingOccurrences(
                    of: "^\\d+\\.\\s*",
                    with: "",
                    options: .regularExpression
                ).trimmingCharacters(in: .whitespaces)

                if !instruction.isEmpty && !instruction.uppercased().contains("INSTRUCTIONS") {
                    instructions.append(instruction)
                }
            }
        }

        // Validation
        guard !ingredients.isEmpty else {
            throw RecipeError.parsingFailed("No ingredients parsed")
        }

        guard !instructions.isEmpty else {
            throw RecipeError.parsingFailed("No instructions parsed")
        }

        return GeneratedRecipe(
            title: title,
            ingredients: ingredients,
            instructions: instructions,
            servings: servings,
            estimatedTime: estimatedTime,
            sourceIngredients: sourceIngredients
        )
    }

    // MARK: - Mock Recipe (Fallback)

    /// Create mock recipe for testing/fallback
    private func createMockRecipe(
        from ingredients: [String],
        preferences: RecipePreferences
    ) -> GeneratedRecipe {
        logger.info("Creating mock recipe from \(ingredients.count) ingredients")

        let primaryIngredients = ingredients.prefix(3).joined(separator: ", ")

        return GeneratedRecipe(
            title: "Simple \(primaryIngredients) Dish",
            ingredients: ingredients.map { "1 cup \($0)" },
            instructions: [
                "Prepare all ingredients by washing and chopping as needed.",
                "Heat a large pan over medium heat with a drizzle of oil.",
                "Add the main ingredients and cook until tender.",
                "Season with salt and pepper to taste.",
                "Serve hot and enjoy!",
            ],
            servings: 2,
            estimatedTime: 30,
            sourceIngredients: ingredients
        )
    }
}

// MARK: - Recipe Preferences

struct RecipePreferences: Sendable {
    let dietaryRestrictions: [String]
    let difficulty: Difficulty?
    let maxCookingTimeMinutes: Int?

    enum Difficulty: String, Sendable {
        case easy = "Easy (beginner-friendly)"
        case medium = "Medium (intermediate skills)"
        case advanced = "Advanced (complex techniques)"
    }

    static let `default` = RecipePreferences(
        dietaryRestrictions: [],
        difficulty: nil,
        maxCookingTimeMinutes: nil
    )
}

// MARK: - Recipe Errors

enum RecipeError: Error, LocalizedError {
    case noIngredients
    case modelNotAvailable(String)
    case generationFailed(String)
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noIngredients:
            return "No ingredients provided for recipe generation"
        case .modelNotAvailable(let message):
            return "AI model not available: \(message)"
        case .generationFailed(let message):
            return "Recipe generation failed: \(message)"
        case .parsingFailed(let message):
            return "Failed to parse recipe: \(message)"
        }
    }
}

// MARK: - Backwards Compatibility

/// Pre-iOS 18.2 compatible wrapper
@MainActor
final class RecipeServiceCompat: ObservableObject {
    @Published private(set) var isGenerating = false
    @Published private(set) var lastError: RecipeError?

    private let logger = Logger(subsystem: "com.crookey.app", category: "RecipeServiceCompat")

    func generateRecipe(
        from ingredients: [String],
        preferences: RecipePreferences = .default
    ) async throws -> GeneratedRecipe {
        isGenerating = true
        defer { isGenerating = false }

        if #available(iOS 18.2, macOS 15.2, *) {
            return try await RecipeService.shared.generateRecipe(
                from: ingredients,
                preferences: preferences
            )
        } else {
            logger.warning("⚠️ Foundation Models not available on this OS version")
            throw RecipeError.modelNotAvailable("Requires iOS 18.2 or later")
        }
    }
}
