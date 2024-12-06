//
//  SettingsManager.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }
    
    private let settingsKey = "app_settings"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = AppSettings.default
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
}

struct AppSettings: Codable {
    var appearance: AppearanceSettings
    var notifications: NotificationSettings
    var privacy: PrivacySettings
    var storage: StorageSettings
    
    static var `default`: AppSettings {
        AppSettings(
            appearance: .default,
            notifications: .default,
            privacy: .default,
            storage: .default
        )
    }
}

struct AppearanceSettings: Codable {
    var colorScheme: ColorScheme
    var accentColor: AccentColor
    var fontSize: FontSize
    
    static var `default`: AppearanceSettings {
        AppearanceSettings(
            colorScheme: .system,
            accentColor: .blue,
            fontSize: .medium
        )
    }
}

struct NotificationSettings: Codable {
    var dailyRecipeEnabled: Bool
    var mealPlanningEnabled: Bool
    var cookingRemindersEnabled: Bool
    var shoppingListRemindersEnabled: Bool
    
    static var `default`: NotificationSettings {
        NotificationSettings(
            dailyRecipeEnabled: true,
            mealPlanningEnabled: true,
            cookingRemindersEnabled: true,
            shoppingListRemindersEnabled: true
        )
    }
}