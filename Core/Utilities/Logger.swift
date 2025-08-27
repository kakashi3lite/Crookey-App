//
//  Logger.swift
//  Crookey
//
//  Created by Elite iOS Engineer on 12/27/24.
//

import Foundation
import os.log

/// Production-grade logging system with structured logging and performance tracking
class Logger {
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.crookey.app", category: "general")
    private let performanceLog = OSLog(subsystem: "com.crookey.app", category: "performance")
    private let mlLog = OSLog(subsystem: "com.crookey.app", category: "machinelearning")
    private let metalLog = OSLog(subsystem: "com.crookey.app", category: "metal")
    
    private init() {}
    
    // MARK: - General Logging
    
    func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        os_log("%@ [%@:%d %@] %@", log: osLog, type: .info, 
               timestamp(), fileName, line, function, message)
    }
    
    func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        os_log("%@ [%@:%d %@] ⚠️ %@", log: osLog, type: .default,
               timestamp(), fileName, line, function, message)
    }
    
    func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let errorDetails = error?.localizedDescription ?? ""
        os_log("%@ [%@:%d %@] ❌ %@ %@", log: osLog, type: .error,
               timestamp(), fileName, line, function, message, errorDetails)
    }
    
    // MARK: - Performance Logging
    
    func logPerformance(_ operation: String, duration: TimeInterval, file: String = #file, function: String = #function) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        os_log("%@ [%@:%@] 🚀 %@ completed in %.3fs", log: performanceLog, type: .info,
               timestamp(), fileName, function, operation, duration)
    }
    
    func logMemoryUsage(_ context: String, bytes: Int64) {
        let mb = Double(bytes) / (1024 * 1024)
        os_log("%@ 📊 %@ - Memory usage: %.2f MB", log: performanceLog, type: .info,
               timestamp(), context, mb)
    }
    
    // MARK: - ML & Metal Logging
    
    func logMLPerformance(_ modelName: String, inferenceTime: TimeInterval, accuracy: Double? = nil) {
        let accuracyText = accuracy != nil ? String(format: " (%.1f%% accuracy)", accuracy! * 100) : ""
        os_log("%@ 🧠 %@ inference: %.3fs%@", log: mlLog, type: .info,
               timestamp(), modelName, inferenceTime, accuracyText)
    }
    
    func logMetalOperation(_ operation: String, duration: TimeInterval, gpuTime: TimeInterval? = nil) {
        let gpuText = gpuTime != nil ? String(format: ", GPU: %.3fs", gpuTime!) : ""
        os_log("%@ ⚡ Metal %@: %.3fs%@", log: metalLog, type: .info,
               timestamp(), operation, duration, gpuText)
    }
    
    // MARK: - Structured Logging for Analytics
    
    func logUserAction(_ action: String, metadata: [String: Any] = [:]) {
        var logMessage = "👤 User Action: \(action)"
        
        if !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " | \(metadataString)"
        }
        
        os_log("%@ %@", log: osLog, type: .info, timestamp(), logMessage)
    }
    
    func logAPICall(_ endpoint: String, method: String, responseTime: TimeInterval, statusCode: Int) {
        let status = statusCode < 400 ? "✅" : "❌"
        os_log("%@ %@ API %@ %@: %d (%.3fs)", log: osLog, type: .info,
               timestamp(), status, method, endpoint, statusCode, responseTime)
    }
    
    // MARK: - Private Helpers
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let coreDataSaveFailed = Notification.Name("coreDataSaveFailed")
    static let metalOperationFailed = Notification.Name("metalOperationFailed")
    static let mlModelLoadFailed = Notification.Name("mlModelLoadFailed")
}