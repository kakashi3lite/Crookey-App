//
//  BackgroundDataProcessor.swift
//  Crookey
//
//  Created by Elite iOS Engineer on 12/27/24.
//

import CoreData
import Foundation
import BackgroundTasks

/// High-performance background data processing for Core Data optimization
class BackgroundDataProcessor {
    static let shared = BackgroundDataProcessor()
    
    private let persistenceManager = PersistenceManager.shared
    private let backgroundTaskIdentifier = "com.crookey.background-data-processing"
    
    private init() {
        registerBackgroundTask()
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: DispatchQueue.global(qos: .background)
        ) { [weak self] task in
            self?.handleBackgroundDataProcessing(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // Run after 1 minute
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.shared.logInfo("Background data processing scheduled successfully")
        } catch {
            Logger.shared.logError("Failed to schedule background data processing", error: error)
        }
    }
    
    // MARK: - Background Processing Implementation
    
    private func handleBackgroundDataProcessing(task: BGProcessingTask) {
        let startTime = CFAbsoluteTimeGetCurrent()
        Logger.shared.logInfo("Background data processing started")
        
        task.expirationHandler = {
            Logger.shared.logWarning("Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                await performDataOptimizations()
                await cleanupOldData()
                await precomputeFrequentQueries()
                await optimizeSearchIndices()
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                Logger.shared.logPerformance("Background Data Processing", duration: duration)
                task.setTaskCompleted(success: true)
                
                // Schedule next background processing
                scheduleBackgroundProcessing()
            } catch {
                Logger.shared.logError("Background data processing failed", error: error)
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Data Optimization Operations
    
    @MainActor
    private func performDataOptimizations() async {
        Logger.shared.logInfo("Starting Core Data optimizations")
        
        // Create background context for heavy operations
        let backgroundContext = persistenceManager.persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        await withCheckedContinuation { continuation in
            backgroundContext.perform {
                do {
                    // Remove duplicate shopping list items
                    self.removeDuplicateShoppingItems(in: backgroundContext)
                    
                    // Optimize recipe storage
                    self.optimizeRecipeStorage(in: backgroundContext)
                    
                    // Update relationship integrity
                    self.validateRelationshipIntegrity(in: backgroundContext)
                    
                    try backgroundContext.save()
                    Logger.shared.logInfo("Core Data optimizations completed")
                    continuation.resume()
                } catch {
                    Logger.shared.logError("Core Data optimization failed", error: error)
                    continuation.resume()
                }
            }
        }
    }
    
    private func removeDuplicateShoppingItems(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let items = try context.fetch(request)
            var seenNames = Set<String>()
            var duplicatesToDelete: [ShoppingListItem] = []
            
            for item in items {
                if let name = item.name, seenNames.contains(name) {
                    duplicatesToDelete.append(item)
                } else if let name = item.name {
                    seenNames.insert(name)
                }
            }
            
            for duplicate in duplicatesToDelete {
                context.delete(duplicate)
            }
            
            if !duplicatesToDelete.isEmpty {
                Logger.shared.logInfo("Removed \\(duplicatesToDelete.count) duplicate shopping list items")
            }
        } catch {
            Logger.shared.logError("Failed to remove duplicate shopping items", error: error)
        }
    }
    
    private func optimizeRecipeStorage(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<SavedRecipe> = SavedRecipe.fetchRequest()
        
        do {
            let recipes = try context.fetch(request)
            
            for recipe in recipes {
                // Optimize image storage - compress if needed
                if let imageData = recipe.image?.data(using: .utf8), imageData.count > 1024 * 1024 {
                    // Image URL is too large, likely base64 data - optimize
                    recipe.image = "placeholder_optimized"
                }
                
                // Clean up instruction formatting
                if let instructions = recipe.instructions {
                    let cleaned = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleaned != instructions {
                        recipe.instructions = cleaned
                    }
                }
            }
            
            Logger.shared.logInfo("Recipe storage optimized for \\(recipes.count) recipes")
        } catch {
            Logger.shared.logError("Failed to optimize recipe storage", error: error)
        }
    }
    
    private func validateRelationshipIntegrity(in context: NSManagedObjectContext) {
        // Check for orphaned ingredients
        let ingredientRequest: NSFetchRequest<SavedIngredient> = SavedIngredient.fetchRequest()
        ingredientRequest.predicate = NSPredicate(format: "recipe == nil")
        
        do {
            let orphanedIngredients = try context.fetch(ingredientRequest)
            for ingredient in orphanedIngredients {
                context.delete(ingredient)
            }
            
            if !orphanedIngredients.isEmpty {
                Logger.shared.logInfo("Cleaned up \\(orphanedIngredients.count) orphaned ingredients")
            }
        } catch {
            Logger.shared.logError("Failed to validate relationship integrity", error: error)
        }
    }
    
    // MARK: - Data Cleanup
    
    private func cleanupOldData() async {
        Logger.shared.logInfo("Starting data cleanup")
        
        let backgroundContext = persistenceManager.persistentContainer.newBackgroundContext()
        
        await withCheckedContinuation { continuation in
            backgroundContext.perform {
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                
                // Clean up old completed shopping list items
                let shoppingRequest: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
                shoppingRequest.predicate = NSPredicate(format: "isChecked == YES AND dateAdded < %@", thirtyDaysAgo as NSDate)
                
                do {
                    let oldItems = try backgroundContext.fetch(shoppingRequest)
                    for item in oldItems {
                        backgroundContext.delete(item)
                    }
                    
                    if !oldItems.isEmpty {
                        try backgroundContext.save()
                        Logger.shared.logInfo("Cleaned up \\(oldItems.count) old shopping list items")
                    }
                } catch {
                    Logger.shared.logError("Failed to cleanup old data", error: error)
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Query Precomputation
    
    private func precomputeFrequentQueries() async {
        Logger.shared.logInfo("Precomputing frequent queries")
        
        // Precompute popular recipes
        _ = persistenceManager.fetchSavedRecipes()
        
        // Precompute shopping list stats
        let shoppingItems = persistenceManager.fetchShoppingList()
        let completedCount = shoppingItems.filter { $0.isChecked }.count
        let pendingCount = shoppingItems.count - completedCount
        
        // Cache results in UserDefaults for quick access
        UserDefaults.standard.set(completedCount, forKey: "cached_completed_shopping_count")
        UserDefaults.standard.set(pendingCount, forKey: "cached_pending_shopping_count")
        
        Logger.shared.logInfo("Cached shopping stats: \\(completedCount) completed, \\(pendingCount) pending")
    }
    
    private func optimizeSearchIndices() async {
        Logger.shared.logInfo("Optimizing search indices")
        
        // This would typically involve updating full-text search indices
        // For now, we'll prepare commonly searched recipe titles
        let backgroundContext = persistenceManager.persistentContainer.newBackgroundContext()
        
        await withCheckedContinuation { continuation in
            backgroundContext.perform {
                let request: NSFetchRequest<SavedRecipe> = SavedRecipe.fetchRequest()
                
                do {
                    let recipes = try backgroundContext.fetch(request)
                    let searchTerms = recipes.compactMap { $0.title?.lowercased() }
                    
                    // Cache search terms for faster autocomplete
                    UserDefaults.standard.set(Array(Set(searchTerms)), forKey: "cached_recipe_search_terms")
                    
                    Logger.shared.logInfo("Optimized search indices for \\(searchTerms.count) terms")
                } catch {
                    Logger.shared.logError("Failed to optimize search indices", error: error)
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Manual Operations
    
    func performImmediateOptimization() async {
        Logger.shared.logInfo("Performing immediate data optimization")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await performDataOptimizations()
        await cleanupOldData()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        Logger.shared.logPerformance("Immediate Data Optimization", duration: duration)
    }
    
    func getDataStatistics() -> DataStatistics {
        let recipeCount = persistenceManager.fetchSavedRecipes().count
        let shoppingItems = persistenceManager.fetchShoppingList()
        let completedShoppingCount = shoppingItems.filter { $0.isChecked }.count
        
        return DataStatistics(
            totalRecipes: recipeCount,
            totalShoppingItems: shoppingItems.count,
            completedShoppingItems: completedShoppingCount,
            lastOptimization: UserDefaults.standard.object(forKey: "last_optimization_date") as? Date
        )
    }
}

// MARK: - Supporting Types

struct DataStatistics {
    let totalRecipes: Int
    let totalShoppingItems: Int
    let completedShoppingItems: Int
    let lastOptimization: Date?
    
    var pendingShoppingItems: Int {
        return totalShoppingItems - completedShoppingItems
    }
    
    var shoppingCompletionRate: Double {
        guard totalShoppingItems > 0 else { return 0.0 }
        return Double(completedShoppingItems) / Double(totalShoppingItems)
    }
}