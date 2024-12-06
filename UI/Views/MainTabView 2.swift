//
//  MainTabView 2.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct MainTabView: View {
    @StateObject private var recipeViewModel = RecipeViewModel()
    @StateObject private var mealPlanViewModel = MealPlanningViewModel()
    @StateObject private var socialViewModel = SocialFeedViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(recipeViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            SearchRecipesView()
                .environmentObject(recipeViewModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            MealPlanningView()
                .environmentObject(mealPlanViewModel)
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }
            
            SocialFeedView()
                .environmentObject(socialViewModel)
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}