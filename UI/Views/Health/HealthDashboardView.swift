//
//  HealthDashboardView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI
import Charts

struct HealthDashboardView: View {
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var selectedTimeFrame: TimeFrame = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppTheme.Layout.spacing * 2) {
                    // Time Frame Selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Daily Summary Card
                    if let today = viewModel.todaySummary {
                        DailyNutritionCard(summary: today)
                    }
                    
                    // Nutrition Charts
                    VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
                        Text("Nutrition Trends")
                            .font(AppTheme.Fonts.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Layout.spacing) {
                                CalorieChart(data: viewModel.calorieData)
                                    .frame(width: 300, height: 200)
                                
                                MacronutrientChart(data: viewModel.macroData)
                                    .frame(width: 300, height: 200)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Goals Progress
                    GoalsProgressView(goals: viewModel.nutritionGoals)
                }
                .padding(.vertical)
            }
            .navigationTitle("Health Dashboard")
            .refreshable {
                await viewModel.refreshData()
            }
        }
    }
}

struct DailyNutritionCard: View {
    let summary: NutritionSummary
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            Text("Today's Nutrition")
                .font(AppTheme.Fonts.headline)
            
            HStack {
                NutrientCircle(
                    value: Int(summary.calories),
                    label: "Calories",
                    color: .orange
                )
                
                Spacer()
                
                NutrientCircle(
                    value: Int(summary.protein),
                    label: "Protein",
                    color: .blue
                )
                
                Spacer()
                
                NutrientCircle(
                    value: Int(summary.carbs),
                    label: "Carbs",
                    color: .green
                )
                
                Spacer()
                
                NutrientCircle(
                    value: Int(summary.fat),
                    label: "Fat",
                    color: .red
                )
            }
            .padding()
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}