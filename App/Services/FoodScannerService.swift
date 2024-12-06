//
//  FoodScannerService.swift
//  Crookey
//
//  Created by Swanand Tanavade on 12/5/24.
//


import Vision
import UIKit
import CoreML

class FoodScannerService {
    static let shared = FoodScannerService()
    
    private var classificationRequest: VNCoreMLRequest?
    private var completionHandler: ((FoodAnalysis) -> Void)?
    
    init() {
        setupVision()
    }
    
    private func setupVision() {
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc"),
              let model = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: model) else {
            print("Failed to load ML model")
            return
        }
        
        classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassification)
    }
    
    func analyzeFood(image: UIImage, completion: @escaping (FoodAnalysis) -> Void) {
        guard let cgImage = image.cgImage else { return }
        
        self.completionHandler = completion
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([classificationRequest].compactMap { $0 })
        } catch {
            print("Failed to perform classification: \(error)")
        }
    }
    
    private func handleClassification(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else { return }
        
        let analysis = FoodAnalysis(
            confidence: Double(topResult.confidence),
            classification: classificationFromString(topResult.identifier),
            nutritionalInfo: nil,
            freshness: freshnessFromConfidence(Double(topResult.confidence))
        )
        
        DispatchQueue.main.async {
            self.completionHandler?(analysis)
        }
    }
    
    private func classificationFromString(_ string: String) -> FoodClassification {
        // Add your classification logic here
        return .unknown
    }
    
    private func freshnessFromConfidence(_ confidence: Double) -> Freshness {
        switch confidence {
        case 0.8...1.0: return .fresh
        case 0.6..<0.8: return .moderate
        case 0.0..<0.6: return .spoiled
        default: return .unknown
        }
    }
}