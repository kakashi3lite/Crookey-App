//
//  MealPlanningView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct MealPlanningView: View {
    @StateObject private var viewModel = MealPlanningViewModel()
    @State private var showingGenerateSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacing) {
                    if viewModel.currentPlan == nil {
                        EmptyMealPlanView()
                    } else {
                        MealPlanCalendarView(mealPlan: viewModel.currentPlan!)
                        
                        // Nutritional Summary
                        NutritionalSummaryCard(summary: viewModel.weeklyNutritionSummary)
                        
                        // Shopping List Preview
                        ShoppingListPreviewCard(ingredients: viewModel.plannedIngredients)
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Planning")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingGenerateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingGenerateSheet) {
                GenerateMealPlanView(viewModel: viewModel)
            }
        }
    }
}

struct GenerateMealPlanView: View {
    @ObservedObject var viewModel: MealPlanningViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var numberOfDays = 7
    @State private var includedMeals: Set<MealType> = [.breakfast, .lunch, .dinner]
    @State private var dietaryPreferences: DietaryPreferences = .default
    
    var body: some View {
        NavigationView {
            Form {
                Section("Plan Duration") {
                    Stepper("Number of Days: \(numberOfDays)", value: $numberOfDays, in: 1...14)
                }
                
                Section("Meals to Include") {
                    ForEach(MealType.allCases) { mealType in
                        Toggle(mealType.displayName, isOn: Binding(
                            get: { includedMeals.contains(mealType) },
                            set: { isIncluded in
                                if isIncluded {
                                    includedMeals.insert(mealType)
                                } else {
                                    includedMeals.remove(mealType)
                                }
                            }
                        ))
                    }
                }
                
                Section("Dietary Preferences") {
                    NavigationLink("Preferences") {
                        DietaryPreferencesView(preferences: $dietaryPreferences)
                    }
                }
            }
            .navigationTitle("Generate Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        Task {
                            await viewModel.generateMealPlan(
                                days: numberOfDays,
                                meals: includedMeals,
                                preferences: dietaryPreferences
                            )
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct MealPlanCalendarView: View {
    let mealPlan: MealPlan
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            ForEach(mealPlan.days) { day in
                DayPlanCard(day: day)
            }
        }
    }
}

struct DayPlanCard: View {
    let day: MealPlanDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                .font(AppTheme.Fonts.headline)
            
            ForEach(Array(zip(day.meals.indices, day.meals)), id: \.0) { index, meal in
                MealRow(meal: meal, type: MealType.allCases[index])
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .shadow(radius: 2)
    }
}