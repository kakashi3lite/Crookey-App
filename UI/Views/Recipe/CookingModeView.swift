//
//  CookingModeView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI
import AVFoundation

struct CookingModeView: View {
    let recipe: Recipe
    @StateObject private var viewModel: CookingModeViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _viewModel = StateObject(wrappedValue: CookingModeViewModel(recipe: recipe))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Layout.spacing) {
                    // Timer Section
                    if viewModel.isTimerActive {
                        TimerView(
                            remainingTime: viewModel.remainingTime,
                            progress: viewModel.timerProgress
                        )
                    }
                    
                    // Steps Section
                    StepCardView(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps,
                        instructions: viewModel.currentInstructions
                    )
                    
                    Spacer()
                    
                    // Controls
                    VStack(spacing: AppTheme.Layout.spacing * 2) {
                        // Navigation Controls
                        HStack(spacing: AppTheme.Layout.spacing * 3) {
                            ControlButton(icon: "chevron.left") {
                                viewModel.previousStep()
                            }
                            .disabled(!viewModel.hasPreviousStep)
                            
                            PlayPauseButton(
                                isPlaying: viewModel.isVoiceEnabled,
                                action: viewModel.toggleVoice
                            )
                            
                            ControlButton(icon: "chevron.right") {
                                viewModel.nextStep()
                            }
                            .disabled(!viewModel.hasNextStep)
                        }
                        
                        // Timer Controls
                        if viewModel.currentStepHasTimer {
                            HStack {
                                if viewModel.isTimerActive {
                                    Button("Cancel Timer") {
                                        viewModel.cancelTimer()
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                } else {
                                    Button("Start Timer (\(viewModel.currentStepDuration)min)") {
                                        viewModel.startTimer()
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Cooking Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.toggleKeepScreenOn) {
                        Image(systemName: viewModel.keepScreenOn ? "lightbulb.fill" : "lightbulb")
                    }
                }
            }
        }
    }
}

struct TimerView: View {
    let remainingTime: TimeInterval
    let progress: Double
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            ZStack {
                Circle()
                    .stroke(AppTheme.primary.opacity(0.2), lineWidth: 10)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.primary, style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round
                    ))
                    .rotationEffect(.degrees(-90))
                
                Text(timeString(from: remainingTime))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
            }
            .frame(width: 200, height: 200)
            
            Text("Time Remaining")
                .font(AppTheme.Fonts.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StepCardView: View {
    let currentStep: Int
    let totalSteps: Int
    let instructions: String
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            // Progress Header
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(AppTheme.Fonts.headline)
                
                Spacer()
                
                Text("\(Int((Double(currentStep + 1) / Double(totalSteps)) * 100))%")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(AppTheme.primary)
                        .frame(width: geometry.size.width * CGFloat(Double(currentStep + 1) / Double(totalSteps)), height: 4)
                }
            }
            .frame(height: 4)
            
            // Instructions
            ScrollView {
                Text(instructions)
                    .font(AppTheme.Fonts.body)
                    .padding()
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.Layout.cornerRadius)
        }
    }
}