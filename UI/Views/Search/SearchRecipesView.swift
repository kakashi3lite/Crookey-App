//
//  SearchRecipesView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct SearchRecipesView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText, onSearch: {
                    viewModel.searchRecipes(query: searchText)
                })
                .padding()
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(text: "Filters", icon: "slider.horizontal.3") {
                            showingFilters = true
                        }
                        
                        ForEach(viewModel.activeFilters, id: \.self) { filter in
                            FilterChip(text: filter) {
                                viewModel.removeFilter(filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Results
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.recipes.isEmpty {
                    EmptySearchView()
                } else {
                    RecipeList(recipes: viewModel.recipes)
                }
            }
            .navigationTitle("Search Recipes")
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(selectedFilters: $viewModel.activeFilters)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search recipes...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearch()
                }
            
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No recipes found")
                .font(.headline)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
    }
}