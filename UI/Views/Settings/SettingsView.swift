//
//  SettingsView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Appearance Section
                Section("Appearance") {
                    Picker("Color Scheme", selection: $viewModel.settings.appearance.colorScheme) {
                        ForEach(ColorScheme.allCases) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    
                    Picker("Accent Color", selection: $viewModel.settings.appearance.accentColor) {
                        ForEach(AccentColor.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                    
                    Picker("Font Size", selection: $viewModel.settings.appearance.fontSize) {
                        ForEach(FontSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    Toggle("Daily Recipe", isOn: $viewModel.settings.notifications.dailyRecipeEnabled)
                    Toggle("Meal Planning", isOn: $viewModel.settings.notifications.mealPlanningEnabled)
                    Toggle("Cooking Reminders", isOn: $viewModel.settings.notifications.cookingRemindersEnabled)
                    Toggle("Shopping List", isOn: $viewModel.settings.notifications.shoppingListRemindersEnabled)
                }
                
                // Privacy Section
                Section("Privacy") {
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView(settings: $viewModel.settings.privacy)
                    }
                }
                
                // Storage Section
                Section("Storage") {
                    NavigationLink("Storage Settings") {
                        StorageSettingsView(settings: $viewModel.settings.storage)
                    }
                }
                
                // About Section
                Section {
                    Button("Rate App") {
                        viewModel.rateApp()
                    }
                    
                    Button("Share App") {
                        viewModel.shareApp()
                    }
                    
                    NavigationLink("About") {
                        AboutView()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}