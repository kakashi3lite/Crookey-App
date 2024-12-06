//
//  HealthKitService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import HealthKit
import Foundation

class HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private let nutritionTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
        HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
        HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!
    ]
    
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: nutritionTypes, read: nutritionTypes)
    }
    
    func saveNutritionData(for recipe: Recipe, servings: Double = 1.0) async throws {
        guard let nutritionInfo = recipe.nutritionalInfo else { return }
        
        let samples = createNutritionSamples(from: nutritionInfo, servings: servings)
        try await healthStore.save(samples)
    }
    
    private func createNutritionSamples(from nutrition: NutritionalInfo, servings: Double) -> [HKSample] {
        let now = Date()
        var samples: [HKSample] = []
        
        // Calories
        if let caloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let calories = HKQuantity(unit: .kilocalorie(), doubleValue: Double(nutrition.calories) * servings)
            let calSample = HKQuantitySample(type: caloriesType, quantity: calories, start: now, end: now)
            samples.append(calSample)
        }
        
        // Protein
        if let proteinType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let protein = HKQuantity(unit: .gram(), doubleValue: nutrition.protein * servings)
            let proteinSample = HKQuantitySample(type: proteinType, quantity: protein, start: now, end: now)
            samples.append(proteinSample)
        }
        
        // Add similar for carbs and fats
        
        return samples
    }
    
    func getNutritionSummary(for date: Date) async throws -> NutritionSummary {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        async let calories = getTotalCalories(start: startDate, end: endDate)
        async let protein = getTotalProtein(start: startDate, end: endDate)
        async let carbs = getTotalCarbs(start: startDate, end: endDate)
        async let fat = getTotalFat(start: startDate, end: endDate)
        
        return try await NutritionSummary(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            date: date
        )
    }
    
    private func getTotalCalories(start: Date, end: Date) async throws -> Double {
        try await getQuantitySum(
            for: .dietaryEnergyConsumed,
            unit: .kilocalorie(),
            start: start,
            end: end
        )
    }
    
    private func getQuantitySum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let sum = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: sum)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthError: Error {
    case invalidType
    case unauthorized
    case queryFailed
}

struct NutritionSummary {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: Date
}