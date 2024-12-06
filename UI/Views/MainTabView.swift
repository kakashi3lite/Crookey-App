//
//  MainTabView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var recipeViewModel = RecipeViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeDiscoveryView()
                .tabItem {
                    Label("Discover", systemImage: "sparkles")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            FoodScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(2)
            
            SavedRecipesView()
                .tabItem {
                    Label("Saved", systemImage: "heart.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(AppTheme.primary)
        .environmentObject(recipeViewModel)
    }
}