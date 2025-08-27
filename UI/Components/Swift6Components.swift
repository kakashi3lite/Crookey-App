//
//  Swift6Components.swift
//  Crookey
//
//  Created by Elite iOS Swift 6 UX Specialist on 12/27/24.
//

import SwiftUI
import Metal
import MetalPerformanceShaders

// MARK: - Metal-Enhanced UI Components for Swift 6

/// Metal-accelerated food image view with real-time enhancement
@available(iOS 18.0, *)
struct MetalFoodImageView: View {
    let image: UIImage
    let enhancement: Enhancement
    let overlays: [ImageOverlay]
    
    @State private var enhancedImage: UIImage?
    @State private var isProcessing: Bool = false
    @State private var confidence: Double = 0.0
    
    enum Enhancement {
        case realTimeOptimization
        case nutritionAnalysis
        case freshnessDetection
        case none
    }
    
    enum ImageOverlay {
        case freshnessIndicator
        case nutritionHeatmap
        case confidenceRing
    }
    
    var body: some View {
        ZStack {
            // Base image with Metal enhancement
            if let enhancedImage = enhancedImage {
                Image(uiImage: enhancedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .transition(.opacity.combined(with: .scale))
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .overlay(
                        ZStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                    .foregroundStyle(.white)
                            }
                        }
                    )
            }
            
            // Overlay components
            ForEach(Array(overlays.enumerated()), id: \.offset) { index, overlay in
                overlayView(for: overlay)
            }
        }
        .onAppear {
            Task {
                await enhanceImage()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
    
    @MainActor
    private func enhanceImage() async {
        guard enhancement != .none else { return }
        
        isProcessing = true
        
        if let metalProcessor = MetalImageProcessor.shared {
            switch enhancement {
            case .realTimeOptimization:
                metalProcessor.enhanceFoodImage(image) { [self] result, error in
                    Task { @MainActor in
                        self.enhancedImage = result
                        self.isProcessing = false
                        if result != nil {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                self.confidence = 0.9 // Mock confidence for demo
                            }
                        }
                    }
                }
            case .nutritionAnalysis, .freshnessDetection:
                // Additional processing modes would be implemented here
                break
            case .none:
                break
            }
        } else {
            // Fallback without Metal acceleration
            isProcessing = false
        }
    }
    
    @ViewBuilder
    private func overlayView(for overlay: ImageOverlay) -> some View {
        switch overlay {
        case .freshnessIndicator:
            FreshnessIndicatorView(confidence: confidence)
        case .nutritionHeatmap:
            NutritionHeatmapView(confidence: confidence)
        case .confidenceRing:
            ConfidenceRingView(confidence: confidence)
        }
    }
    
    private var accessibilityDescription: String {
        var description = "Food image"
        if confidence > 0.8 {
            description += " with high confidence analysis"
        }
        if overlays.contains(.freshnessIndicator) {
            description += ", freshness indicators visible"
        }
        return description
    }
}

// MARK: - Confidence Ring Component

@available(iOS 18.0, *)
struct ConfidenceRingView: View {
    let confidence: Double
    let metalAccelerated: Bool
    let animation: AnimationStyle
    
    @State private var animatedConfidence: Double = 0.0
    
    enum AnimationStyle {
        case fluid(speed: Double)
        case progressive
        case instant
    }
    
    init(confidence: Double, metalAccelerated: Bool = true, animation: AnimationStyle = .fluid(speed: 0.8)) {
        self.confidence = confidence
        self.metalAccelerated = metalAccelerated
        self.animation = animation
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.clear, .white.opacity(0.3)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    lineWidth: 3
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedConfidence)
                .stroke(
                    confidenceGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Confidence percentage
            Text("\(Int(animatedConfidence * 100))%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .frame(width: 60, height: 60)
        .onChange(of: confidence) { _, newValue in
            animateConfidence(to: newValue)
        }
    }
    
    private var confidenceGradient: AngularGradient {
        let colors: [Color] = animatedConfidence > 0.8 ? 
            [.green, .mint] : animatedConfidence > 0.6 ? 
            [.yellow, .orange] : [.red, .pink]
        
        return AngularGradient(
            colors: colors,
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * animatedConfidence)
        )
    }
    
    private func animateConfidence(to newValue: Double) {
        switch animation {
        case .fluid(let speed):
            withAnimation(.easeInOut(duration: 1.0 / speed)) {
                animatedConfidence = newValue
            }
        case .progressive:
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                animatedConfidence = newValue
            }
        case .instant:
            animatedConfidence = newValue
        }
    }
}

// MARK: - Smart Text Field with AI Suggestions

@available(iOS 18.0, *)
struct SmartTextField: View {
    @Binding var text: String
    let suggestions: [String]
    let placeholder: String
    let metalEnhanced: Bool
    
    @State private var showSuggestions: Bool = false
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, suggestions: [String] = [], placeholder: String = "", metalEnhanced: Bool = true) {
        self._text = text
        self.suggestions = suggestions
        self.placeholder = placeholder
        self.metalEnhanced = metalEnhanced
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main text field
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    showSuggestions = !newValue.isEmpty && !suggestions.isEmpty
                }
                .onSubmit {
                    showSuggestions = false
                }
            
            // AI-powered suggestions
            if showSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filteredSuggestions.prefix(3), id: \\.self) { suggestion in
                        Button(action: {
                            text = suggestion
                            showSuggestions = false
                            isFocused = false
                        }) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                
                                Text(suggestion)
                                    .foregroundStyle(.primary)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSuggestions)
    }
    
    private var filteredSuggestions: [String] {
        guard !text.isEmpty else { return suggestions }
        return suggestions.filter { $0.localizedCaseInsensitiveContains(text) }
    }
}

// MARK: - Gesture Control System

@available(iOS 18.0, *)
struct GestureControlView<Content: View>: View {
    let content: Content
    let gestures: [GestureType: () -> Void]
    
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    enum GestureType {
        case swipeUp
        case swipeDown
        case tap
        case longPress
        case doubleTap
    }
    
    init(@ViewBuilder content: () -> Content, gestures: [GestureType: () -> Void]) {
        self.content = content()
        self.gestures = gestures
    }
    
    var body: some View {
        content
            .onTapGesture {
                executeGesture(.tap)
            }
            .onTapGesture(count: 2) {
                executeGesture(.doubleTap)
            }
            .onLongPressGesture {
                executeGesture(.longPress)
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let direction = value.translation
                        if abs(direction.y) > abs(direction.x) {
                            if direction.y < 0 {
                                executeGesture(.swipeUp)
                            } else {
                                executeGesture(.swipeDown)
                            }
                        }
                    }
            )
    }
    
    private func executeGesture(_ type: GestureType) {
        if let action = gestures[type] {
            feedbackGenerator.impactOccurred()
            action()
        }
    }
}

// MARK: - Progressive Loading View

@available(iOS 18.0, *)
struct ProgressiveLoadingView<Content: View>: View {
    let stages: [LoadingStage]
    let content: Content
    
    @State private var currentStage: Int = 0
    @State private var isComplete: Bool = false
    
    struct LoadingStage {
        let title: String
        let duration: TimeInterval
        let icon: String
    }
    
    init(stages: [LoadingStage], @ViewBuilder content: () -> Content) {
        self.stages = stages
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isComplete {
                content
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .identity
                    ))
            } else {
                loadingView
                    .transition(.opacity)
            }
        }
        .onAppear {
            startProgressiveLoading()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            // Current stage icon
            Image(systemName: stages[currentStage].icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.primary)
                .symbolEffect(.pulse, isActive: true)
            
            // Stage title
            Text(stages[currentStage].title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Progress indicator
            ProgressView(value: Double(currentStage + 1), total: Double(stages.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .frame(width: 200)
        }
        .padding(40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func startProgressiveLoading() {
        guard !stages.isEmpty else {
            isComplete = true
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: stages[currentStage].duration, repeats: false) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                if currentStage < stages.count - 1 {
                    currentStage += 1
                    startProgressiveLoading()
                } else {
                    isComplete = true
                }
            }
        }
    }
}

// MARK: - Adaptive Grid Layout

@available(iOS 18.0, *)
struct AdaptiveGridLayout<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    @State private var containerSize: CGSize = .zero
    
    private var adaptiveColumns: [GridItem] {
        let minItemWidth: CGFloat = 150
        let spacing: CGFloat = 12
        let availableWidth = containerSize.width - (spacing * 2)
        let numberOfColumns = max(1, Int(availableWidth / (minItemWidth + spacing)))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfColumns)
    }
    
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: adaptiveColumns, spacing: 12) {
                ForEach(items) { item in
                    content(item)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .padding(.horizontal)
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    containerSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    containerSize = newSize
                }
            }
        )
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, *)
private struct FreshnessIndicatorView: View {
    let confidence: Double
    
    var body: some View {
        HStack {
            Circle()
                .fill(freshnessColor)
                .frame(width: 12, height: 12)
            
            Text(freshnessText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.6), in: Capsule())
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
        .opacity(confidence > 0 ? 1 : 0)
    }
    
    private var freshnessColor: Color {
        confidence > 0.8 ? .green : confidence > 0.6 ? .yellow : .red
    }
    
    private var freshnessText: String {
        confidence > 0.8 ? "Fresh" : confidence > 0.6 ? "Good" : "Check"
    }
}

@available(iOS 18.0, *)
private struct NutritionHeatmapView: View {
    let confidence: Double
    
    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [.green.opacity(0.3), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 50
                )
            )
            .allowsHitTesting(false)
            .opacity(confidence > 0 ? 0.8 : 0)
            .animation(.easeInOut(duration: 0.5), value: confidence)
    }
}

// MARK: - Convenience Extensions

extension View {
    @available(iOS 18.0, *)
    func gestureControlled(_ gestures: [GestureControlView<Self>.GestureType: () -> Void]) -> some View {
        GestureControlView(content: { self }, gestures: gestures)
    }
    
    @available(iOS 18.0, *)
    func progressiveLoading(stages: [ProgressiveLoadingView<Self>.LoadingStage]) -> some View {
        ProgressiveLoadingView(stages: stages) { self }
    }
}