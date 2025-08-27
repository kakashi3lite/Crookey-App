//
//  PerformanceBenchmark.swift
//  Crookey
//
//  Created by Elite iOS Engineer on 12/27/24.
//

import Foundation
import Metal
import MetalPerformanceShaders
import UIKit

/// Comprehensive performance benchmarking and testing suite
class PerformanceBenchmark {
    static let shared = PerformanceBenchmark()
    
    private var benchmarkResults: [BenchmarkResult] = []
    private let testQueue = DispatchQueue(label: "com.crookey.performance-testing", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Core Data Performance Tests
    
    func benchmarkCoreDataOperations() async -> CoreDataBenchmarkResult {
        Logger.shared.logInfo("Starting Core Data performance benchmark")
        
        let persistenceManager = PersistenceManager.shared
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test recipe creation
        let recipeCreationTime = await measureAsyncOperation {
            let testRecipe = Recipe(
                id: Int.random(in: 1...10000),
                title: "Benchmark Recipe \\(UUID().uuidString)",
                readyInMinutes: 30,
                servings: 4,
                image: "test-image",
                summary: "Test recipe for performance benchmarking",
                instructions: "Step 1: Test\\nStep 2: Benchmark\\nStep 3: Complete",
                healthScore: 85.0,
                diets: ["test"],
                ingredients: [
                    Ingredient(id: 1, name: "Test Ingredient 1", amount: 1.0, unit: "cup", image: nil),
                    Ingredient(id: 2, name: "Test Ingredient 2", amount: 2.0, unit: "tbsp", image: nil)
                ]
            )
            persistenceManager.saveRecipe(testRecipe)
        }
        
        // Test recipe fetching
        let recipeFetchTime = await measureAsyncOperation {
            _ = persistenceManager.fetchSavedRecipes()
        }
        
        // Test shopping list operations
        let shoppingListTime = await measureAsyncOperation {
            let testIngredients = [
                Ingredient(id: 100, name: "Benchmark Item", amount: 1.0, unit: "piece", image: nil)
            ]
            persistenceManager.addToShoppingList(testIngredients)
            _ = persistenceManager.fetchShoppingList()
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = CoreDataBenchmarkResult(
            recipeCreationTime: recipeCreationTime,
            recipeFetchTime: recipeFetchTime,
            shoppingListTime: shoppingListTime,
            totalTime: totalTime
        )
        
        Logger.shared.logPerformance("Core Data Benchmark", duration: totalTime)
        return result
    }
    
    // MARK: - Metal Performance Tests
    
    func benchmarkMetalOperations() async -> MetalBenchmarkResult {
        Logger.shared.logInfo("Starting Metal performance benchmark")
        
        guard let metalProcessor = MetalImageProcessor.shared else {
            Logger.shared.logError("Metal processor not available for benchmarking")
            return MetalBenchmarkResult.unavailable()
        }
        
        // Create test image
        let testImage = createTestFoodImage()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Benchmark food enhancement
        let enhancementTime = await measureAsyncOperation {
            await withCheckedContinuation { continuation in
                metalProcessor.enhanceFoodImage(testImage) { _, _ in
                    continuation.resume()
                }
            }
        }
        
        // Benchmark advanced analysis
        let analysisTime = await measureAsyncOperation {
            await withCheckedContinuation { continuation in
                metalProcessor.analyzeFoodAdvanced(testImage) { _, _ in
                    continuation.resume()
                }
            }
        }
        
        // Benchmark freshness detection
        let freshnessTime = await measureAsyncOperation {
            await withCheckedContinuation { continuation in
                metalProcessor.detectFreshness(testImage) { _, _ in
                    continuation.resume()
                }
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = MetalBenchmarkResult(
            enhancementTime: enhancementTime,
            analysisTime: analysisTime,
            freshnessTime: freshnessTime,
            totalTime: totalTime,
            isAvailable: true
        )
        
        Logger.shared.logPerformance("Metal Operations Benchmark", duration: totalTime)
        return result
    }
    
    // MARK: - ML Performance Tests
    
    func benchmarkMLOperations() async -> MLBenchmarkResult {
        Logger.shared.logInfo("Starting ML performance benchmark")
        
        let foodScanner = FoodScannerService.shared
        let testImage = createTestFoodImage()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Benchmark food classification
        let classificationTime = await measureAsyncOperation {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    foodScanner.analyzeFood(image: testImage) { _ in
                        continuation.resume()
                    }
                }
            }
        }
        
        // Benchmark multiple concurrent operations
        let concurrentStartTime = CFAbsoluteTimeGetCurrent()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    await withCheckedContinuation { continuation in
                        Task { @MainActor in
                            foodScanner.analyzeFood(image: testImage) { _ in
                                continuation.resume()
                            }
                        }
                    }
                }
            }
        }
        let concurrentTime = CFAbsoluteTimeGetCurrent() - concurrentStartTime
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = MLBenchmarkResult(
            singleClassificationTime: classificationTime,
            concurrentClassificationTime: concurrentTime,
            totalTime: totalTime
        )
        
        Logger.shared.logPerformance("ML Operations Benchmark", duration: totalTime)
        return result
    }
    
    // MARK: - Memory Performance Tests
    
    func benchmarkMemoryUsage() -> MemoryBenchmarkResult {
        Logger.shared.logInfo("Starting memory usage benchmark")
        
        let startMemory = getMemoryUsage()
        
        // Create memory pressure
        var testData: [Data] = []
        for _ in 0..<100 {
            let data = Data(count: 1024 * 1024) // 1MB blocks
            testData.append(data)
        }
        
        let peakMemory = getMemoryUsage()
        
        // Release memory
        testData.removeAll()
        
        // Force garbage collection
        autoreleasepool {
            // Memory cleanup
        }
        
        let endMemory = getMemoryUsage()
        
        let result = MemoryBenchmarkResult(
            startMemory: startMemory,
            peakMemory: peakMemory,
            endMemory: endMemory,
            memoryPressure: peakMemory - startMemory,
            memoryRecovered: peakMemory - endMemory
        )
        
        Logger.shared.logMemoryUsage("Memory Benchmark", bytes: peakMemory)
        return result
    }
    
    // MARK: - Comprehensive Benchmark Suite
    
    func runComprehensiveBenchmark() async -> ComprehensiveBenchmarkResult {
        Logger.shared.logInfo("Starting comprehensive performance benchmark suite")
        let overallStart = CFAbsoluteTimeGetCurrent()
        
        async let coreDataResult = benchmarkCoreDataOperations()
        async let metalResult = benchmarkMetalOperations()
        async let mlResult = benchmarkMLOperations()
        let memoryResult = benchmarkMemoryUsage()
        
        let results = await (
            coreData: coreDataResult,
            metal: metalResult,
            ml: mlResult,
            memory: memoryResult
        )
        
        let totalTime = CFAbsoluteTimeGetCurrent() - overallStart
        
        let comprehensiveResult = ComprehensiveBenchmarkResult(
            coreDataBenchmark: results.coreData,
            metalBenchmark: results.metal,
            mlBenchmark: results.ml,
            memoryBenchmark: results.memory,
            totalBenchmarkTime: totalTime,
            deviceInfo: collectDeviceInfo(),
            timestamp: Date()
        )
        
        // Store result
        benchmarkResults.append(BenchmarkResult.comprehensive(comprehensiveResult))
        
        // Generate performance report
        let report = generatePerformanceReport(comprehensiveResult)
        Logger.shared.logInfo("Benchmark completed. \\(report)")
        
        return comprehensiveResult
    }
    
    // MARK: - Utility Methods
    
    private func measureAsyncOperation(_ operation: () async -> Void) async -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        await operation()
        return CFAbsoluteTimeGetCurrent() - startTime
    }
    
    private func createTestFoodImage() -> UIImage {
        // Create a synthetic food image for testing
        UIGraphicsBeginImageContext(CGSize(width: 224, height: 224))
        
        // Draw a simple "food-like" pattern
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemOrange.cgColor)
        context?.fillEllipse(in: CGRect(x: 50, y: 50, width: 124, height: 124))
        
        context?.setFillColor(UIColor.systemGreen.cgColor)
        context?.fillEllipse(in: CGRect(x: 20, y: 20, width: 40, height: 40))
        
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func collectDeviceInfo() -> DevicePerformanceInfo {
        return DevicePerformanceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            processorCount: ProcessInfo.processInfo.processorCount,
            physicalMemory: Int64(ProcessInfo.processInfo.physicalMemory),
            metalSupported: MTLCreateSystemDefaultDevice() != nil
        )
    }
    
    private func generatePerformanceReport(_ result: ComprehensiveBenchmarkResult) -> String {
        var report = "Performance Report:\\n"
        report += "- Core Data: \\(String(format: "%.3f", result.coreDataBenchmark.totalTime))s\\n"
        report += "- Metal: \\(result.metalBenchmark.isAvailable ? String(format: "%.3f", result.metalBenchmark.totalTime) + "s" : "N/A")\\n"
        report += "- ML: \\(String(format: "%.3f", result.mlBenchmark.totalTime))s\\n"
        report += "- Memory Peak: \\(result.memoryBenchmark.peakMemory / (1024*1024))MB"
        return report
    }
    
    // MARK: - Public Interface
    
    func getBenchmarkHistory() -> [BenchmarkResult] {
        return benchmarkResults
    }
    
    func clearBenchmarkHistory() {
        benchmarkResults.removeAll()
        Logger.shared.logInfo("Benchmark history cleared")
    }
    
    func getLatestBenchmark() -> BenchmarkResult? {
        return benchmarkResults.last
    }
}

// MARK: - Benchmark Result Types

struct CoreDataBenchmarkResult {
    let recipeCreationTime: TimeInterval
    let recipeFetchTime: TimeInterval
    let shoppingListTime: TimeInterval
    let totalTime: TimeInterval
}

struct MetalBenchmarkResult {
    let enhancementTime: TimeInterval
    let analysisTime: TimeInterval
    let freshnessTime: TimeInterval
    let totalTime: TimeInterval
    let isAvailable: Bool
    
    static func unavailable() -> MetalBenchmarkResult {
        return MetalBenchmarkResult(
            enhancementTime: 0,
            analysisTime: 0,
            freshnessTime: 0,
            totalTime: 0,
            isAvailable: false
        )
    }
}

struct MLBenchmarkResult {
    let singleClassificationTime: TimeInterval
    let concurrentClassificationTime: TimeInterval
    let totalTime: TimeInterval
}

struct MemoryBenchmarkResult {
    let startMemory: Int64
    let peakMemory: Int64
    let endMemory: Int64
    let memoryPressure: Int64
    let memoryRecovered: Int64
}

struct ComprehensiveBenchmarkResult {
    let coreDataBenchmark: CoreDataBenchmarkResult
    let metalBenchmark: MetalBenchmarkResult
    let mlBenchmark: MLBenchmarkResult
    let memoryBenchmark: MemoryBenchmarkResult
    let totalBenchmarkTime: TimeInterval
    let deviceInfo: DevicePerformanceInfo
    let timestamp: Date
}

struct DevicePerformanceInfo {
    let model: String
    let systemVersion: String
    let processorCount: Int
    let physicalMemory: Int64
    let metalSupported: Bool
}

enum BenchmarkResult {
    case coreData(CoreDataBenchmarkResult)
    case metal(MetalBenchmarkResult)
    case ml(MLBenchmarkResult)
    case memory(MemoryBenchmarkResult)
    case comprehensive(ComprehensiveBenchmarkResult)
}