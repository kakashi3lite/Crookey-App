//
//  RecipeDiscoveryView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct RecipeDiscoveryView: View {
    @EnvironmentObject var viewModel: RecipeViewModel
    @State private var cardOffset: CGSize = .zero
    @State private var showRecipeDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Layout.spacing) {
                    if let recipe = viewModel.currentRecipe {
                        RecipeCard(recipe: recipe) {
                            // Recipe liked
                            withAnimation(AppTheme.Animation.spring) {
                                viewModel.saveRecipe(recipe)
                                viewModel.fetchRandomRecipe()
                            }
                        } onDislike: {
                            // Recipe disliked
                            withAnimation(AppTheme.Animation.spring) {
                                viewModel.fetchRandomRecipe()
                            }
                        }
                        .onTapGesture {
                            showRecipeDetail = true
                        }
                    } else if viewModel.isLoading {
                        LoadingView()
                    } else {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "No Recipes",
                            message: "Tap to discover new recipes"
                        )
                        .onTapGesture {
                            viewModel.fetchRandomRecipe()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Discover Recipes")
            .sheet(isPresented: $showRecipeDetail) {
                if let recipe = viewModel.currentRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding delicious recipes...")
                .font(AppTheme.Fonts.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing * 2) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.primary)
            
            Text(title)
                .font(AppTheme.Fonts.title)
            
            Text(message)
                .font(AppTheme.Fonts.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}