//
//  EnhancedFoodScannerView.swift
//  Crookey
//
//  Created by Elite iOS Swift 6 UX Specialist on 12/27/24.
//

import SwiftUI
import AVFoundation

@available(iOS 18.0, *)
struct EnhancedFoodScannerView: View {
    @StateObject private var scannerManager = FoodScannerManager()
    @State private var showResults: Bool = false
    @State private var analysisResult: FoodAnalysis?
    @State private var scannerState: ScannerState = .idle
    
    enum ScannerState {
        case idle
        case scanning
        case analyzing
        case completed
        case error(String)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Header with state
                    scannerHeader
                        .frame(height: 100)
                    
                    // Camera view or results
                    cameraContent
                        .frame(height: geometry.size.height * 0.6)
                    
                    // Controls
                    controlsSection
                        .frame(height: geometry.size.height * 0.25)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupScanner()
        }
        .gestureControlled([
            .swipeUp: { nextAction() },
            .tap: { captureImage() },
            .longPress: { showCameraSettings() }
        ])
    }
    
    // MARK: - Header
    
    private var scannerHeader: some View {
        VStack(spacing: 8) {
            // Status indicator
            HStack {
                statusIndicator
                
                Spacer()
                
                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            
            // State description
            Text(stateDescription)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .animation(.easeInOut, value: scannerState)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Food Scanner")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                if case .analyzing = scannerState {
                    HStack(spacing: 4) {
                        Text("Analyzing...")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                            .scaleEffect(0.7)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch scannerState {
        case .idle:
            Image(systemName: "camera")
                .font(.title2)
                .foregroundStyle(.white)
        case .scanning:
            Image(systemName: "viewfinder")
                .font(.title2)
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
        case .analyzing:
            Image(systemName: "brain")
                .font(.title2)
                .foregroundStyle(.green)
                .symbolEffect(.variableColor)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
    }
    
    private var stateDescription: String {
        switch scannerState {
        case .idle:
            return "Point your camera at food to get started"
        case .scanning:
            return "Position food in frame and tap to capture"
        case .analyzing:
            return "Analyzing food with Metal acceleration..."
        case .completed:
            return "Analysis complete! View results below"
        case .error(let message):
            return "Error: \\(message)"
        }
    }
    
    // MARK: - Camera Content
    
    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            if showResults, let result = analysisResult {
                // Results view
                FoodAnalysisResultsView(result: result)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                // Camera view
                cameraPreview
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
    
    private var cameraPreview: some View {
        ZStack {
            // Camera preview
            if scannerManager.isSessionRunning {
                CameraPreviewView(session: scannerManager.session)
                    .overlay(
                        scannerOverlay
                    )
            } else {
                // Placeholder when camera unavailable
                RoundedRectangle(cornerRadius: 20)
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray)
                            
                            Text("Camera Unavailable")
                                .font(.headline)
                                .foregroundStyle(.gray)
                        }
                    )
            }
        }
    }
    
    private var scannerOverlay: some View {
        ZStack {
            // Scanner frame
            ScannerFrameView(isActive: scannerState == .scanning)
            
            // Metal enhancement visualization
            if case .analyzing = scannerState {
                MetalProcessingOverlay(progress: scannerManager.processingProgress)
                    .transition(.opacity)
            }
            
            // AI coaching bubbles
            if scannerManager.showCoachingTip, let tip = scannerManager.currentTip {
                CoachingBubbleView(tip: tip)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Quick actions
            if case .completed = scannerState {
                quickActionsView
            }
            
            // Main controls
            HStack(spacing: 40) {
                // Flash toggle
                ControlButton(
                    icon: scannerManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill",
                    isActive: scannerManager.isFlashOn
                ) {
                    toggleFlash()
                }
                
                // Capture button
                CaptureButton(
                    state: scannerState,
                    action: captureImage
                )
                
                // Camera flip
                ControlButton(
                    icon: "arrow.triangle.2.circlepath.camera",
                    isActive: false
                ) {
                    flipCamera()
                }
            }
            
            // Secondary controls
            HStack(spacing: 30) {
                // Gallery
                Button(action: selectFromGallery) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Gallery")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                
                // Settings
                Button(action: showCameraSettings) {
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                        Text("Settings")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                
                // Help
                Button(action: showHelp) {
                    VStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                        Text("Help")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var quickActionsView: some View {
        if let result = analysisResult {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionCard(
                        icon: "heart.fill",
                        title: "Save",
                        subtitle: "Add to favorites"
                    ) {
                        saveFood(result)
                    }
                    
                    QuickActionCard(
                        icon: "magnifyingglass",
                        title: "Recipes",
                        subtitle: "Find recipes"
                    ) {
                        findRecipes(result)
                    }
                    
                    QuickActionCard(
                        icon: "chart.bar.fill",
                        title: "Nutrition",
                        subtitle: "View details"
                    ) {
                        showNutrition(result)
                    }
                    
                    QuickActionCard(
                        icon: "cart.fill",
                        title: "Shop",
                        subtitle: "Add to list"
                    ) {
                        addToShoppingList(result)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Actions
    
    private func setupScanner() {
        scannerManager.setupSession { success in
            if success {
                scannerState = .scanning
            } else {
                scannerState = .error("Failed to setup camera")
            }
        }
    }
    
    private func captureImage() {
        guard case .scanning = scannerState else { return }
        
        scannerState = .analyzing
        
        scannerManager.capturePhoto { image in
            analyzeImage(image)
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        Task { @MainActor in
            do {
                let result = try await scannerManager.analyzeFood(image)
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    analysisResult = result
                    scannerState = .completed
                    showResults = true
                }
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
            } catch {
                scannerState = .error(error.localizedDescription)
                
                // Auto-retry after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        scannerState = .scanning
                    }
                }
            }
        }
    }
    
    private func nextAction() {
        switch scannerState {
        case .idle:
            scannerState = .scanning
        case .completed:
            resetScanner()
        default:
            break
        }
    }
    
    private func resetScanner() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showResults = false
            analysisResult = nil
            scannerState = .scanning
        }
    }
    
    private func toggleFlash() {
        scannerManager.toggleFlash()
    }
    
    private func flipCamera() {
        scannerManager.flipCamera()
    }
    
    private func selectFromGallery() {
        // Implementation would show photo picker
    }
    
    private func showCameraSettings() {
        // Implementation would show camera settings
    }
    
    private func showHelp() {
        // Implementation would show help overlay
    }
    
    private func dismiss() {
        // Implementation would dismiss the view
    }
    
    // MARK: - Quick Actions
    
    private func saveFood(_ result: FoodAnalysis) {
        // Implementation
    }
    
    private func findRecipes(_ result: FoodAnalysis) {
        // Implementation
    }
    
    private func showNutrition(_ result: FoodAnalysis) {
        // Implementation
    }
    
    private func addToShoppingList(_ result: FoodAnalysis) {
        // Implementation
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, *)
struct ScannerFrameView: View {
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Corner brackets
            VStack {
                HStack {
                    ScannerCornerView(corner: .topLeft)
                    Spacer()
                    ScannerCornerView(corner: .topRight)
                }
                Spacer()
                HStack {
                    ScannerCornerView(corner: .bottomLeft)
                    Spacer()
                    ScannerCornerView(corner: .bottomRight)
                }
            }
            .padding(24)
            
            // Scanning line
            if isActive {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .green, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(y: -50)
                    .animation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isActive
                    )
            }
        }
    }
}

@available(iOS 18.0, *)
private struct ScannerCornerView: View {
    let corner: Corner
    
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    var body: some View {
        Path { path in
            let length: CGFloat = 30
            
            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.addLine(to: CGPoint(x: length, y: length))
            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: length, y: length))
            case .bottomRight:
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: CGPoint(x: length, y: length))
                path.addLine(to: CGPoint(x: length, y: 0))
            }
        }
        .stroke(.white, lineWidth: 3)
    }
}

@available(iOS 18.0, *)
struct MetalProcessingOverlay: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Processing indicator
            HStack(spacing: 8) {
                Image(systemName: "gpu")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolEffect(.variableColor, isActive: true)
                
                Text("Metal Processing")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            
            // Progress visualization
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .background(.black.opacity(0.7))
        .cornerRadius(16)
    }
}

@available(iOS 18.0, *)
struct CoachingBubbleView: View {
    let tip: String
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        
                        Text("Tip")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

@available(iOS 18.0, *)
struct CaptureButton: View {
    let state: EnhancedFoodScannerView.ScannerState
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(.black.opacity(0.2), lineWidth: 2)
                    .frame(width: 70, height: 70)
                
                if case .analyzing = state {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Circle()
                        .fill(.black)
                        .frame(width: 60, height: 60)
                }
            }
        }
        .disabled(!canCapture)
        .scaleEffect(canCapture ? 1.0 : 0.9)
        .opacity(canCapture ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }
    
    private var canCapture: Bool {
        switch state {
        case .scanning:
            return true
        default:
            return false
        }
    }
}

@available(iOS 18.0, *)
struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isActive ? .yellow : .white)
                .frame(width: 50, height: 50)
                .background(.black.opacity(0.3))
                .clipShape(Circle())
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

@available(iOS 18.0, *)
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 80, height: 80)
            .background(.black.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scanner Manager

@available(iOS 18.0, *)
@MainActor
class FoodScannerManager: ObservableObject {
    @Published var isSessionRunning: Bool = false
    @Published var isFlashOn: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var showCoachingTip: Bool = false
    @Published var currentTip: String?
    
    let session = AVCaptureSession()
    private let foodScannerService = FoodScannerService.shared
    
    func setupSession(completion: @escaping (Bool) -> Void) {
        // Implementation would setup AVCaptureSession
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSessionRunning = true
            completion(true)
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        // Implementation would capture photo
        // For now, create a placeholder image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let image = UIImage(systemName: "photo") ?? UIImage()
            completion(image)
        }
    }
    
    func analyzeFood(_ image: UIImage) async throws -> FoodAnalysis {
        // Simulate Metal processing progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            await MainActor.run {
                processingProgress = progress
            }
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            foodScannerService.analyzeFood(image: image) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
        // Implementation would control actual flash
    }
    
    func flipCamera() {
        // Implementation would switch camera
    }
}

// MARK: - Results View

@available(iOS 18.0, *)
struct FoodAnalysisResultsView: View {
    let result: FoodAnalysis
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food classification
                VStack(spacing: 12) {
                    HStack {
                        Text(result.classification.emoji)
                            .font(.system(size: 40))
                        
                        VStack(alignment: .leading) {
                            Text(result.classification.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text("\\(Int(result.confidence * 100))% confidence")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                        
                        Spacer()
                    }
                    
                    // Freshness indicator
                    HStack {
                        Text(result.freshness.emoji)
                        Text(result.freshness.description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                    }
                }
                
                // Nutrition information
                if let nutrition = result.nutritionalInfo {
                    NutritionCard(nutrition: nutrition)
                }
                
                // Alternative results
                if !result.alternativeResults.isEmpty {
                    AlternativeResultsView(alternatives: result.alternativeResults)
                }
            }
            .padding()
        }
    }
}

@available(iOS 18.0, *)
private struct NutritionCard: View {
    let nutrition: NutritionalInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Facts")
                .font(.headline)
                .foregroundStyle(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                NutritionItem(label: "Calories", value: "\\(nutrition.calories)")
                NutritionItem(label: "Protein", value: String(format: "%.1fg", nutrition.protein))
                NutritionItem(label: "Carbs", value: String(format: "%.1fg", nutrition.carbs))
                NutritionItem(label: "Fat", value: String(format: "%.1fg", nutrition.fat))
            }
        }
        .padding(16)
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, *)
private struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.white.opacity(0.1))
        .cornerRadius(8)
    }
}

@available(iOS 18.0, *)
private struct AlternativeResultsView: View {
    let alternatives: [(identifier: String, confidence: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other possibilities:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
            
            ForEach(Array(alternatives.prefix(3).enumerated()), id: \\.offset) { index, alternative in
                HStack {
                    Text("\\(index + 2).")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(alternative.identifier)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\\(Int(alternative.confidence * 100))%")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }
}