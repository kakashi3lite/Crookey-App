//
//  AppTheme.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI

enum AppTheme {
    // Colors
    static let primary = Color("Primary", bundle: nil) // Deep blue: #2C3E50
    static let accent = Color("Accent", bundle: nil) // Orange: #E67E22
    static let background = Color("Background", bundle: nil) // Light gray: #F5F6F7
    static let cardBackground = Color.white
    
    // Typography
    struct Fonts {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
    }
    
    // Layout
    struct Layout {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 8
    }
    
    // Animations
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
}