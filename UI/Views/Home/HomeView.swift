//
//  HomeView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack {
                    if recipeViewModel.isLoading {
                        ProgressView()
                    } else if let recipe = recipeViewModel.currentRecipe {
                        RecipeCard(recipe: recipe) {
                            // Like action
                            recipeViewModel.saveRecipe(recipe)
                            recipeViewModel.fetchRandomRecipe()
                        } onDislike: {
                            // Dislike action
                            recipeViewModel.skipRecipe()
                        }
                        .onTapGesture {
                            showDetail = true
                        }
                    } else {
                        Button("Find Recipes") {
                            recipeViewModel.fetchRandomRecipe()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Discover")
            .sheet(isPresented: $showDetail) {
                if let recipe = recipeViewModel.currentRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
        .onAppear {
            if recipeViewModel.currentRecipe == nil {
                recipeViewModel.fetchRandomRecipe()
            }
        }
    }
}