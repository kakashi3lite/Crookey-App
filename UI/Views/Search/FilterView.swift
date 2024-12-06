//
//  FilterView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FilterViewModel
    
    init(selectedFilters: Binding<Set<String>>) {
        _viewModel = StateObject(wrappedValue: FilterViewModel(selectedFilters: selectedFilters))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Cuisines
                Section("Cuisine") {
                    ForEach(viewModel.cuisines, id: \.self) { cuisine in
                        FilterToggle(
                            isOn: viewModel.bindingForFilter(cuisine),
                            label: cuisine
                        )
                    }
                }
                
                // Diets
                Section("Diet") {
                    ForEach(viewModel.diets, id: \.self) { diet in
                        FilterToggle(
                            isOn: viewModel.bindingForFilter(diet),
                            label: diet
                        )
                    }
                }
                
                // Meal Types
                Section("Meal Type") {
                    ForEach(viewModel.mealTypes, id: \.self) { type in
                        FilterToggle(
                            isOn: viewModel.bindingForFilter(type),
                            label: type
                        )
                    }
                }
                
                // Cooking Time
                Section("Cooking Time") {
                    Picker("Maximum Time", selection: $viewModel.maxCookingTime) {
                        ForEach(viewModel.cookingTimeOptions, id: \.self) { time in
                            Text(time == 0 ? "Any" : "\(time) minutes")
                        }
                    }
                }
                
                // Intolerances
                Section("Intolerances") {
                    ForEach(viewModel.intolerances, id: \.self) { intolerance in
                        FilterToggle(
                            isOn: viewModel.bindingForFilter(intolerance),
                            label: intolerance
                        )
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        viewModel.applyFilters()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterToggle: View {
    @Binding var isOn: Bool
    let label: String
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(AppTheme.Fonts.body)
        }
    }
}

struct SearchSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
            Text("Popular Searches")
                .font(AppTheme.Fonts.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Layout.spacing) {
                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionButton(text: suggestion) {
                        onSuggestionTap(suggestion)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SuggestionButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.text)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.Layout.cornerRadius)
        }
    }
}