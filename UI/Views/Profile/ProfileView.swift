//
//  ProfileView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    HStack(spacing: 15) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.primary)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.userName)
                                .font(AppTheme.Fonts.headline)
                            Text(viewModel.userEmail)
                                .font(AppTheme.Fonts.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Dietary Preferences
                Section("Dietary Preferences") {
                    ForEach(viewModel.dietaryPreferences, id: \.self) { preference in
                        Toggle(preference, isOn: viewModel.bindingForPreference(preference))
                    }
                }
                
                // App Settings
                Section("App Settings") {
                    Toggle("Dark Mode", isOn: $isDarkMode)
                    
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    
                    Toggle("Save Recipes Offline", isOn: $viewModel.offlineModeEnabled)
                }
                
                // Statistics
                Section("Your Activity") {
                    StatisticRow(title: "Saved Recipes", value: "\(viewModel.savedRecipesCount)")
                    StatisticRow(title: "Cooked Recipes", value: "\(viewModel.cookedRecipesCount)")
                    StatisticRow(title: "Food Scans", value: "\(viewModel.foodScansCount)")
                }
                
                // Additional Options
                Section {
                    NavigationLink(destination: PreferencesView()) {
                        Label("Preferences", systemImage: "gear")
                    }
                    
                    NavigationLink(destination: PrivacyView()) {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                    
                    Button(action: viewModel.shareApp) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: viewModel.contactSupport) {
                        Label("Contact Support", systemImage: "questionmark.circle")
                    }
                }
                
                // Sign Out
                Section {
                    Button(action: viewModel.signOut) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(AppTheme.Fonts.headline)
                .foregroundColor(AppTheme.primary)
        }
    }
}