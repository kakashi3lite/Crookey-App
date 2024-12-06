//
//  MealPlanningService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Foundation

class MealPlanningService {
    static let shared = MealPlanningService()
    private let persistence = PersistenceManager.shared
    
    func generateMealPlan(
        for days: Int,
        preferences: UserPreferences
    ) async throws -> MealPlan {
        var mealPlan = MealPlan(days: [])
        
        for dayIndex in 0..<days {
            let day = try await generateDayPlan(
                dayOffset: dayIndex,
                preferences: preferences
            )
            mealPlan.days.append(day)
        }
        
        return mealPlan
    }
    
    private func generateDayPlan(
        dayOffset: Int,
        preferences: UserPreferences
    ) async throws -> MealPlanDay {
        async let breakfast = fetchMeal(type: .breakfast, preferences: preferences)
        async let lunch = fetchMeal(type: .lunch, preferences: preferences)
        async let dinner = fetchMeal(type: .dinner, preferences: preferences)
        
        let meals = try await [breakfast, lunch, dinner]
        
        return MealPlanDay(
            date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!,
            meals: meals
        )
    }
    
    func saveMealPlan(_ mealPlan: MealPlan) async throws {
        try await persistence.saveMealPlan(mealPlan)
    }
}

struct MealPlan: Codable, Identifiable {
    let id: UUID
    var days: [MealPlanDay]
    
    init(id: UUID = UUID(), days: [MealPlanDay]) {
        self.id = id
        self.days = days
    }
}

struct MealPlanDay: Codable, Identifiable {
    let id: UUID
    let date: Date
    var meals: [Recipe]
    
    init(id: UUID = UUID(), date: Date, meals: [Recipe]) {
        self.id = id
        self.date = date
        self.meals = meals
    }
}