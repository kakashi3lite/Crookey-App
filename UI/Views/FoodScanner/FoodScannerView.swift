//
//  FoodScannerView.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import SwiftUI
import AVFoundation

struct FoodScannerView: View {
    @StateObject private var viewModel = FoodScannerViewModel()
    @State private var showCamera = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Layout.spacing * 2) {
                    // Camera Preview or Results
                    if viewModel.isScanning {
                        CameraPreviewView(session: viewModel.session)
                            .cornerRadius(AppTheme.Layout.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                                    .stroke(AppTheme.primary, lineWidth: 2)
                            )
                            .overlay(
                                ScannerOverlay(isScanning: viewModel.isAnalyzing)
                            )
                    } else if let result = viewModel.analysisResult {
                        FoodAnalysisResultView(result: result)
                    } else {
                        EmptyScannerView()
                    }
                    
                    // Controls
                    VStack(spacing: AppTheme.Layout.spacing) {
                        if !viewModel.isScanning {
                            PrimaryButton(title: "Start Scanning", icon: "camera.fill") {
                                viewModel.startScanning()
                            }
                        } else {
                            HStack(spacing: AppTheme.Layout.spacing * 2) {
                                ControlButton(icon: "arrow.triangle.2.circlepath") {
                                    viewModel.toggleCamera()
                                }
                                
                                CaptureButton {
                                    viewModel.capturePhoto()
                                }
                                
                                ControlButton(icon: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill") {
                                    viewModel.toggleFlash()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Food Scanner")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

struct ScannerOverlay: View {
    let isScanning: Bool
    
    var body: some View {
        ZStack {
            // Scanner corners
            VStack {
                HStack {
                    ScannerCorner(rotation: 0)
                    Spacer()
                    ScannerCorner(rotation: 90)
                }
                Spacer()
                HStack {
                    ScannerCorner(rotation: 270)
                    Spacer()
                    ScannerCorner(rotation: 180)
                }
            }
            .padding(20)
            
            if isScanning {
                // Scanning animation
                Rectangle()
                    .fill(AppTheme.accent.opacity(0.3))
                    .frame(height: 2)
                    .offset(y: -100)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isScanning
                    )
            }
        }
    }
}

struct ScannerCorner: View {
    let rotation: Double
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(AppTheme.accent, lineWidth: 3)
        .rotationEffect(.degrees(rotation))
    }
}

struct CaptureButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 60, height: 60)
            }
        }
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(AppTheme.primary)
                .clipShape(Circle())
        }
    }
}