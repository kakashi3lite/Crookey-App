//
//  ErrorHandler.swift
//  Crookey
//
//  Created by Elite iOS Engineer on 12/27/24.
//

import Foundation
import UIKit

/// Comprehensive error handling and monitoring system
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private var errorQueue: DispatchQueue
    private var errorCount: Int = 0
    private var lastErrorTime: Date?
    
    private init() {
        self.errorQueue = DispatchQueue(label: "com.crookey.error-handling", qos: .utility)
        setupErrorNotifications()
    }
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        errorQueue.async { [weak self] in
            self?.processError(error, context: context, file: file, function: function, line: line)
        }
    }
    
    private func processError(_ error: Error, context: String, file: String, function: String, line: Int) {
        errorCount += 1
        lastErrorTime = Date()
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        Logger.shared.logError("\\(context.isEmpty ? "" : "\\(context): ")\\(error.localizedDescription)", 
                              error: error, file: file, function: function, line: line)
        
        // Categorize error for appropriate response
        let category = categorizeError(error)
        let severity = determineSeverity(error, category: category)
        
        // Store error for analytics
        storeErrorForAnalytics(error, category: category, severity: severity, context: context)
        
        // Handle based on severity
        handleErrorBySeverity(error, severity: severity, context: context)
        
        // Check for error patterns
        detectErrorPatterns()
    }
    
    // MARK: - Error Categorization
    
    private func categorizeError(_ error: Error) -> ErrorCategory {
        switch error {
        case is URLError:
            return .network
        case is NSError where (error as NSError).domain == NSCocoaErrorDomain:
            return .coreData
        case let mlError where String(describing: type(of: mlError)).contains("ML"):
            return .machineLearning
        case is DecodingError, is EncodingError:
            return .dataParsing
        default:
            return .general
        }
    }
    
    private func determineSeverity(_ error: Error, category: ErrorCategory) -> ErrorSeverity {
        // Critical errors that could crash the app
        if let nsError = error as NSError {
            switch nsError.code {
            case NSFileReadCorruptFileError, NSCoreDataError:
                return .critical
            case NSFileReadNoSuchFileError, NSURLErrorNotConnectedToInternet:
                return .warning
            default:
                break
            }
        }
        
        switch category {
        case .network:
            return .warning // Most network errors are recoverable
        case .coreData:
            return .critical // Data corruption is serious
        case .machineLearning:
            return .error // ML failures affect core functionality
        case .dataParsing:
            return .warning // Usually recoverable
        case .general:
            return .error
        }
    }
    
    // MARK: - Error Response
    
    private func handleErrorBySeverity(_ error: Error, severity: ErrorSeverity, context: String) {
        switch severity {
        case .critical:
            handleCriticalError(error, context: context)
        case .error:
            handleStandardError(error, context: context)
        case .warning:
            handleWarning(error, context: context)
        case .info:
            // Just log, no special handling needed
            break
        }
    }
    
    private func handleCriticalError(_ error: Error, context: String) {
        // Critical errors might require app restart or data recovery
        Logger.shared.logError("CRITICAL ERROR: \\(context)", error: error)
        
        // Notify main thread for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .criticalErrorOccurred,
                object: nil,
                userInfo: [
                    "error": error,
                    "context": context,
                    "timestamp": Date()
                ]
            )
        }
        
        // Attempt automatic recovery
        attemptErrorRecovery(error, context: context)
    }
    
    private func handleStandardError(_ error: Error, context: String) {
        Logger.shared.logError("Standard error in \\(context)", error: error)
        
        // Store for user notification if needed
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .standardErrorOccurred,
                object: nil,
                userInfo: [
                    "error": error,
                    "context": context
                ]
            )
        }
    }
    
    private func handleWarning(_ error: Error, context: String) {
        Logger.shared.logWarning("Warning in \\(context): \\(error.localizedDescription)")
        
        // Check if this warning needs user attention
        if shouldNotifyUserOfWarning(error) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .warningErrorOccurred,
                    object: nil,
                    userInfo: [
                        "error": error,
                        "context": context
                    ]
                )
            }
        }
    }
    
    // MARK: - Error Recovery
    
    private func attemptErrorRecovery(_ error: Error, context: String) {
        Logger.shared.logInfo("Attempting error recovery for: \\(context)")
        
        switch categorizeError(error) {
        case .coreData:
            // Attempt Core Data recovery
            NotificationCenter.default.post(name: .attemptCoreDataRecovery, object: nil)
            
        case .network:
            // Schedule network retry
            scheduleNetworkRetry(context: context)
            
        case .machineLearning:
            // Reset ML models
            NotificationCenter.default.post(name: .resetMLModels, object: nil)
            
        default:
            Logger.shared.logInfo("No specific recovery method for error category")
        }
    }
    
    private func scheduleNetworkRetry(context: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            NotificationCenter.default.post(
                name: .retryNetworkOperation,
                object: nil,
                userInfo: ["context": context]
            )
        }
    }
    
    // MARK: - Error Pattern Detection
    
    private func detectErrorPatterns() {
        // Check for repeated errors in short timeframe
        if errorCount >= 5, let lastTime = lastErrorTime, Date().timeIntervalSince(lastTime) < 60 {
            Logger.shared.logError("Error pattern detected: \\(errorCount) errors in last minute")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .errorPatternDetected,
                    object: nil,
                    userInfo: [
                        "errorCount": self.errorCount,
                        "timeWindow": 60
                    ]
                )
            }
            
            // Reset counter to avoid spam
            errorCount = 0
        }
    }
    
    // MARK: - Error Analytics
    
    private func storeErrorForAnalytics(_ error: Error, category: ErrorCategory, severity: ErrorSeverity, context: String) {
        let errorData = ErrorAnalyticsData(
            timestamp: Date(),
            error: error,
            category: category,
            severity: severity,
            context: context,
            deviceInfo: collectDeviceInfo()
        )
        
        // Store locally for batch upload
        var storedErrors = getStoredErrors()
        storedErrors.append(errorData)
        
        // Keep only last 100 errors
        if storedErrors.count > 100 {
            storedErrors.removeFirst(storedErrors.count - 100)
        }
        
        saveStoredErrors(storedErrors)
    }
    
    private func getStoredErrors() -> [ErrorAnalyticsData] {
        guard let data = UserDefaults.standard.data(forKey: "stored_errors"),
              let errors = try? JSONDecoder().decode([ErrorAnalyticsData].self, from: data) else {
            return []
        }
        return errors
    }
    
    private func saveStoredErrors(_ errors: [ErrorAnalyticsData]) {
        if let data = try? JSONEncoder().encode(errors) {
            UserDefaults.standard.set(data, forKey: "stored_errors")
        }
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        )
    }
    
    // MARK: - Utility Methods
    
    private func shouldNotifyUserOfWarning(_ error: Error) -> Bool {
        // Only notify for user-actionable warnings
        if let urlError = error as? URLError {
            return urlError.code == .notConnectedToInternet
        }
        return false
    }
    
    private func setupErrorNotifications() {
        NotificationCenter.default.addObserver(
            forName: .coreDataSaveFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? Error {
                self?.handle(error, context: "Core Data Save")
            }
        }
    }
    
    // MARK: - Public Interface
    
    func getErrorStatistics() -> ErrorStatistics {
        let storedErrors = getStoredErrors()
        let last24Hours = Date().addingTimeInterval(-86400)
        let recentErrors = storedErrors.filter { $0.timestamp > last24Hours }
        
        return ErrorStatistics(
            totalErrors: storedErrors.count,
            recentErrors: recentErrors.count,
            criticalErrors: recentErrors.filter { $0.severity == .critical }.count,
            mostCommonCategory: findMostCommonCategory(in: recentErrors)
        )
    }
    
    private func findMostCommonCategory(in errors: [ErrorAnalyticsData]) -> ErrorCategory {
        let categoryCounts = Dictionary(grouping: errors, by: { $0.category })
            .mapValues { $0.count }
        
        return categoryCounts.max { $0.value < $1.value }?.key ?? .general
    }
    
    func clearErrorHistory() {
        UserDefaults.standard.removeObject(forKey: "stored_errors")
        errorCount = 0
        lastErrorTime = nil
        Logger.shared.logInfo("Error history cleared")
    }
}

// MARK: - Supporting Types

enum ErrorCategory: String, Codable {
    case network
    case coreData
    case machineLearning
    case dataParsing
    case general
}

enum ErrorSeverity: String, Codable {
    case critical
    case error
    case warning
    case info
}

struct ErrorAnalyticsData: Codable {
    let timestamp: Date
    let errorDescription: String
    let category: ErrorCategory
    let severity: ErrorSeverity
    let context: String
    let deviceInfo: DeviceInfo
    
    init(timestamp: Date, error: Error, category: ErrorCategory, severity: ErrorSeverity, context: String, deviceInfo: DeviceInfo) {
        self.timestamp = timestamp
        self.errorDescription = error.localizedDescription
        self.category = category
        self.severity = severity
        self.context = context
        self.deviceInfo = deviceInfo
    }
}

struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let appVersion: String
}

struct ErrorStatistics {
    let totalErrors: Int
    let recentErrors: Int
    let criticalErrors: Int
    let mostCommonCategory: ErrorCategory
}

// MARK: - Notification Names

extension Notification.Name {
    static let criticalErrorOccurred = Notification.Name("criticalErrorOccurred")
    static let standardErrorOccurred = Notification.Name("standardErrorOccurred")
    static let warningErrorOccurred = Notification.Name("warningErrorOccurred")
    static let errorPatternDetected = Notification.Name("errorPatternDetected")
    
    // Recovery notifications
    static let attemptCoreDataRecovery = Notification.Name("attemptCoreDataRecovery")
    static let resetMLModels = Notification.Name("resetMLModels")
    static let retryNetworkOperation = Notification.Name("retryNetworkOperation")
}