//
//  SearchView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $viewModel.searchQuery)
                    .padding()
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Layout.spacing) {
                        ForEach(viewModel.activeFilters, id: \.self) { filter in
                            FilterChip(text: filter) {
                                viewModel.removeFilter(filter)
                            }
                        }
                        
                        Button(action: { showFilters = true }) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                Text("Filters")
                            }
                            .font(AppTheme.Fonts.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Results
                if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.recipes.isEmpty {
                    if viewModel.searchQuery.isEmpty {
                        SearchSuggestionsView(viewModel: viewModel)
                    } else {
                        EmptySearchView()
                    }
                } else {
                    RecipeList(recipes: viewModel.recipes)
                }
            }
            .navigationTitle("Search Recipes")
            .sheet(isPresented: $showFilters) {
                FilterView(
                    selectedFilters: $viewModel.activeFilters,
                    availableFilters: viewModel.availableFilters
                )
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search recipes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .font(AppTheme.Fonts.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.accent.opacity(0.1))
        .foregroundColor(AppTheme.accent)
        .cornerRadius(20)
    }
}