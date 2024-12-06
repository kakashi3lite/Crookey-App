//
//  RecipeDetailView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Section
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: recipe.image)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 300)
                    .clipped()
                    
                    // Save Button
                    Button(action: viewModel.toggleSave) {
                        Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(viewModel.isSaved ? .red : .white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding()
                    }
                }
                
                // Recipe Info Section
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
                    Text(recipe.title)
                        .font(AppTheme.Fonts.title)
                        .padding(.horizontal)
                    
                    // Quick Info Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Layout.spacing) {
                            RecipeInfoPill(icon: "clock", text: "\(recipe.readyInMinutes) min")
                            RecipeInfoPill(icon: "person.2", text: "\(recipe.servings) servings")
                            if let score = recipe.healthScore {
                                RecipeInfoPill(icon: "heart", text: "\(Int(score))% healthy")
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tab View
                    CustomTabView(selection: $selectedTab)
                    
                    // Content based on selected tab
                    TabContentView(selectedTab: selectedTab, viewModel: viewModel)
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.startCookingMode) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $viewModel.showCookingMode) {
            CookingModeView(recipe: recipe)
        }
    }
}

struct CustomTabView: View {
    @Binding var selection: Int
    private let tabs = ["Overview", "Ingredients", "Steps"]
    
    var body: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                VStack {
                    Text(tabs[index])
                        .font(AppTheme.Fonts.headline)
                        .foregroundColor(selection == index ? AppTheme.primary : .gray)
                    
                    if selection == index {
                        Rectangle()
                            .fill(AppTheme.primary)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    withAnimation {
                        selection = index
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TabContentView: View {
    let selectedTab: Int
    let viewModel: RecipeDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
            switch selectedTab {
            case 0:
                OverviewTab(summary: viewModel.recipe.summary)
            case 1:
                IngredientsTab(ingredients: viewModel.recipe.ingredients ?? [])
            case 2:
                StepsTab(instructions: viewModel.recipe.instructions ?? "")
            default:
                EmptyView()
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
    }
}

struct RecipeInfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(AppTheme.Fonts.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.primary.opacity(0.1))
        .foregroundColor(AppTheme.primary)
        .cornerRadius(20)
    }
}