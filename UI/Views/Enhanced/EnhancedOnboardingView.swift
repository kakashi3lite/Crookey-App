//
//  EnhancedOnboardingView.swift
//  Crookey
//
//  Created by Elite iOS Swift 6 UX Specialist on 12/27/24.
//

import SwiftUI

@available(iOS 18.0, *)
struct EnhancedOnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var currentPage: Int = 0
    @State private var showMainApp: Bool = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color("OnboardingPrimary"),
                    Color("OnboardingSecondary")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showMainApp {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .identity
                    ))
            } else {
                onboardingContent
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: showMainApp)
    }
    
    private var onboardingContent: some View {
        VStack(spacing: 0) {
            // Progress indicator
            OnboardingProgressView(
                currentPage: currentPage,
                totalPages: OnboardingPage.allCases.count
            )
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(OnboardingPage.allCases.enumerated()), id: \.element) { index, page in
                    onboardingPageView(for: page)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onAppear {
                setupPageControlAppearance()
            }
            
            // Navigation controls
            OnboardingControlsView(
                currentPage: $currentPage,
                totalPages: OnboardingPage.allCases.count,
                onComplete: {
                    completeOnboarding()
                }
            )
            .padding(.bottom, 40)
        }
    }
    
    @ViewBuilder
    private func onboardingPageView(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            WelcomePageView()
        case .aiPersonality:
            AIPersonalityPageView(manager: onboardingManager)
        case .metalDemo:
            MetalDemoPageView()
        case .permissions:
            PermissionsPageView(manager: onboardingManager)
        case .firstScan:
            FirstScanPageView(manager: onboardingManager)
        }
    }
    
    private func setupPageControlAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.white)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.white.opacity(0.5))
    }
    
    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5)) {
            showMainApp = true
        }
    }
}

// MARK: - Onboarding Pages

enum OnboardingPage: CaseIterable {
    case welcome
    case aiPersonality
    case metalDemo
    case permissions
    case firstScan
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to Crookey"
        case .aiPersonality: return "Meet Your AI Sous Chef"
        case .metalDemo: return "Supercharged Food Analysis"
        case .permissions: return "Quick Setup"
        case .firstScan: return "Try Your First Scan"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "Your AI-powered cooking companion with Metal acceleration"
        case .aiPersonality: return "Choose how your cooking assistant communicates with you"
        case .metalDemo: return "See how Metal acceleration makes food recognition lightning fast"
        case .permissions: return "Enable features to personalize your cooking experience"
        case .firstScan: return "Let's analyze your first food item together"
        }
    }
}

// MARK: - Welcome Page

@available(iOS 18.0, *)
struct WelcomePageView: View {
    @State private var animateHero: Bool = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Hero animation
            ZStack {
                // Background circles
                ForEach(0..<3, id: \\.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120 + (CGFloat(index) * 40))
                        .scaleEffect(animateHero ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .delay(Double(index) * 0.2)
                            .repeatForever(autoreverses: true),
                            value: animateHero
                        )
                }
                
                // Main icon
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, isActive: animateHero)
            }
            
            VStack(spacing: 20) {
                Text(OnboardingPage.welcome.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(OnboardingPage.welcome.subtitle)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            animateHero = true
        }
    }
}

// MARK: - AI Personality Page

@available(iOS 18.0, *)
struct AIPersonalityPageView: View {
    let manager: OnboardingManager
    @State private var selectedPersonality: AIPersonality = .friendly
    
    enum AIPersonality: String, CaseIterable {
        case professional = "Professional"
        case friendly = "Friendly"
        case motivational = "Motivational"
        
        var icon: String {
            switch self {
            case .professional: return "briefcase.fill"
            case .friendly: return "heart.fill"
            case .motivational: return "flame.fill"
            }
        }
        
        var description: String {
            switch self {
            case .professional: return "Clear, concise instructions with technical precision"
            case .friendly: return "Warm, encouraging guidance with personal touch"
            case .motivational: return "Energetic coaching to inspire your cooking journey"
            }
        }
        
        var sampleMessage: String {
            switch self {
            case .professional: return "This recipe requires 15 minutes prep time. Ensure ingredients are at room temperature."
            case .friendly: return "Let's make something delicious together! This recipe is perfect for beginners."
            case .motivational: return "You've got this, chef! This recipe will showcase your growing skills beautifully."
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse)
                
                VStack(spacing: 8) {
                    Text(OnboardingPage.aiPersonality.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(OnboardingPage.aiPersonality.subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Personality options
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                ForEach(AIPersonality.allCases, id: \\.self) { personality in
                    PersonalityCard(
                        personality: personality,
                        isSelected: selectedPersonality == personality
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPersonality = personality
                            manager.setAIPersonality(personality.rawValue)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

@available(iOS 18.0, *)
private struct PersonalityCard: View {
    let personality: AIPersonalityPageView.AIPersonality
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: personality.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                    
                    Text(personality.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Text(personality.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                // Sample message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sample message:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(""\\(personality.sampleMessage)"")
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.2) : .white.opacity(0.1))
                    .stroke(isSelected ? .white.opacity(0.5) : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Metal Demo Page

@available(iOS 18.0, *)
struct MetalDemoPageView: View {
    @State private var showDemo: Bool = false
    @State private var demoProgress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "gpu")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor, isActive: showDemo)
                
                VStack(spacing: 8) {
                    Text(OnboardingPage.metalDemo.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(OnboardingPage.metalDemo.subtitle)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Demo visualization
            VStack(spacing: 20) {
                // Before/After comparison
                HStack(spacing: 20) {
                    // Before
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Original")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            )
                    }
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: showDemo)
                    
                    // After
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(showDemo ? 0.3 : 0.1))
                            .frame(height: 120)
                            .overlay(
                                VStack {
                                    Image(systemName: "sparkles")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(showDemo ? 1.0 : 0.6))
                                        .symbolEffect(.bounce, isActive: showDemo)
                                    Text("Enhanced")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(showDemo ? 1.0 : 0.6))
                                }
                            )
                            .scaleEffect(showDemo ? 1.05 : 1.0)
                    }
                }
                
                // Progress bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Processing Speed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text("\\(Int(demoProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    
                    ProgressView(value: demoProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .scaleEffect(y: 2)
                }
            }
            .padding(.horizontal)
            
            // Start demo button
            Button("See Metal in Action") {
                startDemo()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(showDemo)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private func startDemo() {
        showDemo = true
        
        // Animate progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            demoProgress += 0.02
            
            if demoProgress >= 1.0 {
                timer.invalidate()
                demoProgress = 1.0
            }
        }
    }
}

// MARK: - Supporting Classes

@available(iOS 18.0, *)
class OnboardingManager: ObservableObject {
    @Published var aiPersonality: String = "Friendly"
    @Published var permissionsGranted: [String: Bool] = [:]
    
    func setAIPersonality(_ personality: String) {
        aiPersonality = personality
        UserDefaults.standard.set(personality, forKey: "ai_personality")
    }
    
    func requestPermission(_ permission: String) {
        // Implementation would handle actual permission requests
        permissionsGranted[permission] = true
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        Logger.shared.logUserAction("Onboarding Completed", metadata: [
            "personality": aiPersonality,
            "permissions": permissionsGranted
        ])
    }
}

// MARK: - Progress and Controls

@available(iOS 18.0, *)
private struct OnboardingProgressView: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \\.self) { index in
                Capsule()
                    .fill(index <= currentPage ? .white : .white.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
    }
}

@available(iOS 18.0, *)
private struct OnboardingControlsView: View {
    @Binding var currentPage: Int
    let totalPages: Int
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            if currentPage > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage -= 1
                    }
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            if currentPage < totalPages - 1 {
                Button("Next") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentPage += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Get Started") {
                    onComplete()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Button Styles

@available(iOS 18.0, *)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Views

@available(iOS 18.0, *)
private struct PermissionsPageView: View {
    let manager: OnboardingManager
    
    var body: some View {
        VStack {
            Text("Permissions Page")
                .foregroundStyle(.white)
            // Implementation would include permission requests
        }
    }
}

@available(iOS 18.0, *)
private struct FirstScanPageView: View {
    let manager: OnboardingManager
    
    var body: some View {
        VStack {
            Text("First Scan Page")
                .foregroundStyle(.white)
            // Implementation would include guided scanning experience
        }
    }
}