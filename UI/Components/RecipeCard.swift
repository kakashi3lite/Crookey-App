//
//  RecipeCard.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    let onLike: () -> Void
    let onDislike: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation = Angle.zero
    @GestureState private var isDragging = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                .fill(AppTheme.cardBackground)
                .shadow(radius: 8)
            
            VStack(spacing: 0) {
                // Recipe Image
                AsyncImage(url: URL(string: recipe.image)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .frame(height: 250)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Recipe Info
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacing) {
                    Text(recipe.title)
                        .font(AppTheme.Fonts.headline)
                        .lineLimit(2)
                    
                    HStack {
                        RecipeInfoBadge(icon: "clock", text: "\(recipe.readyInMinutes)min")
                        RecipeInfoBadge(icon: "person.2", text: "\(recipe.servings) servings")
                        if let score = recipe.healthScore {
                            RecipeInfoBadge(icon: "heart.fill", text: "\(Int(score))%")
                        }
                    }
                    
                    if let diets = recipe.diets, !diets.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(diets, id: \.self) { diet in
                                    DietBadge(text: diet)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .offset(offset)
        .rotationEffect(rotation)
        .gesture(
            DragGesture()
                .updating($isDragging) { value, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Angle(degrees: Double(gesture.translation.width) * 0.1)
                }
                .onEnded { gesture in
                    handleSwipe(translation: gesture.translation)
                }
        )
        .animation(AppTheme.Animation.spring, value: offset)
        .animation(AppTheme.Animation.spring, value: rotation)
    }
    
    private func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 100
        
        if translation.width > threshold {
            offset = CGSize(width: 500, height: 0)
            onLike()
        } else if translation.width < -threshold {
            offset = CGSize(width: -500, height: 0)
            onDislike()
        } else {
            offset = .zero
            rotation = .zero
        }
    }
}

struct RecipeInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(AppTheme.Fonts.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DietBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(AppTheme.Fonts.caption)
            .foregroundColor(AppTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.accent.opacity(0.1))
            .cornerRadius(8)
    }
}