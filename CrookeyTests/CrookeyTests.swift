//
//  CrookeyTests.swift
//  CrookeyTests
//
//  Created by Swanand Tanavade on 12/5/24.
//

import XCTest
@testable import Crookey

final class CrookeyTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
    }
    
    // MARK: - Recipe Model Tests
    
    func testRecipeModelCreation() throws {
        let recipe = Recipe(
            id: 1,
            title: "Test Recipe",
            readyInMinutes: 30,
            servings: 4,
            image: "test.jpg",
            summary: "A test recipe",
            instructions: "Test instructions",
            healthScore: 85.0,
            diets: ["vegetarian"],
            ingredients: nil
        )
        
        XCTAssertEqual(recipe.id, 1)
        XCTAssertEqual(recipe.title, "Test Recipe")
        XCTAssertEqual(recipe.readyInMinutes, 30)
        XCTAssertEqual(recipe.servings, 4)
        XCTAssertFalse(recipe.isFavorite)
    }
    
    // MARK: - Food Analysis Tests
    
    func testFoodAnalysisCreation() throws {
        let nutritionalInfo = NutritionalInfo(
            calories: 200,
            protein: 10.0,
            carbs: 30.0,
            fat: 5.0,
            vitamins: ["C": 50.0]
        )
        
        let foodAnalysis = FoodAnalysis(
            confidence: 0.95,
            classification: .fruit,
            nutritionalInfo: nutritionalInfo,
            freshness: .fresh
        )
        
        XCTAssertEqual(foodAnalysis.confidence, 0.95)
        XCTAssertEqual(foodAnalysis.classification, .fruit)
        XCTAssertEqual(foodAnalysis.freshness, .fresh)
        XCTAssertNotNil(foodAnalysis.nutritionalInfo)
    }
    
    // MARK: - Performance Tests
    
    func testRecipeDecodingPerformance() throws {
        let jsonData = """
        {
            "id": 1,
            "title": "Test Recipe",
            "readyInMinutes": 30,
            "servings": 4,
            "image": "test.jpg",
            "summary": "A test recipe"
        }
        """.data(using: .utf8)!
        
        measure {
            do {
                let _ = try JSONDecoder().decode(Recipe.self, from: jsonData)
            } catch {
                XCTFail("Failed to decode recipe: \(error)")
            }
        }
    }
}