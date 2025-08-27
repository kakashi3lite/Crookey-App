# Context Saving Implementation Guide - Crookey

## Developer Implementation Guide

This document provides practical implementation examples and code patterns for working with the Crookey context saving system.

---

## 1. Adding New Persistent Data Models

### Core Data Entity Creation

When adding new entities to the Core Data model:

```swift
// 1. Update Crookey.xcdatamodeld with new entity
// 2. Create the entity class (if not auto-generated)

@NSManaged class MealPlan: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdDate: Date
    @NSManaged var title: String
    @NSManaged var days: Set<MealPlanDay>
}

// 3. Add persistence methods to PersistenceManager
extension PersistenceManager {
    func saveMealPlan(_ mealPlan: MealPlan) {
        // Implementation
        let entity = MealPlan(context: context)
        entity.id = mealPlan.id
        entity.createdDate = Date()
        entity.title = mealPlan.title
        
        saveContext()
    }
    
    func fetchMealPlans() -> [MealPlan] {
        let request: NSFetchRequest<MealPlan> = MealPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching meal plans: \(error)")
            return []
        }
    }
}
```

---

## 2. Creating Context-Aware ViewModels

### Base ViewModel Pattern

```swift
class BaseContextViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    
    private var contextSaveTimer: Timer?
    private let contextSaveDelay: TimeInterval = 2.0 // Auto-save after 2 seconds of inactivity
    
    func scheduleContextSave() {
        contextSaveTimer?.invalidate()
        contextSaveTimer = Timer.scheduledTimer(withTimeInterval: contextSaveDelay, repeats: false) { _ in
            Task { @MainActor in
                await self.saveContext()
            }
        }
    }
    
    @MainActor
    func saveContext() async {
        // Override in subclasses
        PersistenceManager.shared.saveContext()
    }
    
    deinit {
        contextSaveTimer?.invalidate()
    }
}
```

### Example: Recipe Context ViewModel

```swift
class RecipeViewModel: BaseContextViewModel {
    @Published var currentRecipe: Recipe?
    @Published var savedRecipes: [Recipe] = []
    @Published var searchHistory: [String] = []
    @Published var favoriteRecipes: Set<Int> = []
    
    private let persistenceManager = PersistenceManager.shared
    private let settingsManager = SettingsManager.shared
    
    override init() {
        super.init()
        loadSavedContext()
    }
    
    private func loadSavedContext() {
        // Load saved recipes
        savedRecipes = persistenceManager.fetchSavedRecipes()
        
        // Load search history from UserDefaults
        if let historyData = UserDefaults.standard.data(forKey: "searchHistory"),
           let history = try? JSONDecoder().decode([String].self, from: historyData) {
            searchHistory = history
        }
        
        // Load favorites
        if let favoritesData = UserDefaults.standard.data(forKey: "favoriteRecipes"),
           let favorites = try? JSONDecoder().decode(Set<Int>.self, from: favoritesData) {
            favoriteRecipes = favorites
        }
    }
    
    @MainActor
    override func saveContext() async {
        super.saveContext()
        
        // Save search history
        if let historyData = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(historyData, forKey: "searchHistory")
        }
        
        // Save favorites
        if let favoritesData = try? JSONEncoder().encode(favoriteRecipes) {
            UserDefaults.standard.set(favoritesData, forKey: "favoriteRecipes")
        }
    }
    
    func addToSearchHistory(_ query: String) {
        searchHistory.insert(query, at: 0)
        if searchHistory.count > 10 {
            searchHistory.removeLast()
        }
        scheduleContextSave()
    }
    
    func toggleFavorite(_ recipeId: Int) {
        if favoriteRecipes.contains(recipeId) {
            favoriteRecipes.remove(recipeId)
        } else {
            favoriteRecipes.insert(recipeId)
        }
        scheduleContextSave()
    }
}
```

---

## 3. Implementing Settings Context

### Custom Settings Implementation

```swift
// Extend AppSettings for new preferences
extension AppSettings {
    struct CookingSettings: Codable {
        var preferredUnits: MeasurementUnit = .metric
        var cookingSkillLevel: SkillLevel = .beginner
        var availableCookingTime: TimeInterval = 3600 // 1 hour default
        var kitchenEquipment: Set<Equipment> = []
        
        enum MeasurementUnit: String, Codable, CaseIterable {
            case metric, imperial
        }
        
        enum SkillLevel: String, Codable, CaseIterable {
            case beginner, intermediate, advanced
        }
        
        enum Equipment: String, Codable, CaseIterable {
            case oven, microwave, blender, foodProcessor, standMixer
        }
    }
}

// Update SettingsManager
extension SettingsManager {
    func updateCookingSettings(_ settings: AppSettings.CookingSettings) {
        self.settings.cooking = settings
        // Settings will automatically save due to @Published didSet
    }
    
    func getCookingSettings() -> AppSettings.CookingSettings {
        return settings.cooking
    }
}
```

---

## 4. Cloud Sync Implementation

### Sync-Aware Data Models

```swift
protocol SyncableModel: Codable {
    var id: String { get }
    var lastModified: Date { get set }
    var syncStatus: SyncStatus { get set }
}

enum SyncStatus: String, Codable {
    case local      // Only exists locally
    case synced     // In sync with cloud
    case pending    // Has local changes waiting to sync
    case conflict   // Conflicted with cloud version
}

// Example implementation
struct SyncableRecipe: SyncableModel {
    let id: String
    var lastModified: Date
    var syncStatus: SyncStatus = .local
    
    // Recipe properties
    let title: String
    let ingredients: [Ingredient]
    let instructions: String
    // ... other properties
}
```

### Sync Service Enhancement

```swift
extension SyncService {
    func syncModel<T: SyncableModel>(_ model: T, to collection: String) async throws {
        let docRef = db.collection(collection).document(model.id)
        
        do {
            // Check for conflicts
            let cloudDoc = try await docRef.getDocument()
            if let cloudData = cloudDoc.data(),
               let cloudTimestamp = cloudData["lastModified"] as? Timestamp,
               cloudTimestamp.dateValue() > model.lastModified {
                
                // Handle conflict
                try await handleSyncConflict(local: model, cloud: cloudData, docRef: docRef)
            } else {
                // Safe to upload
                var syncedModel = model
                syncedModel.lastModified = Date()
                syncedModel.syncStatus = .synced
                
                try await docRef.setData(syncedModel.dictionary)
            }
        } catch {
            // Mark as pending for retry
            var pendingModel = model
            pendingModel.syncStatus = .pending
            updateLocalModel(pendingModel)
            throw error
        }
    }
    
    private func handleSyncConflict<T: SyncableModel>(
        local: T, 
        cloud: [String: Any], 
        docRef: DocumentReference
    ) async throws {
        // Implement conflict resolution strategy
        // For now, use last-write-wins, but could implement more sophisticated resolution
        
        // Option 1: Cloud wins (discard local changes)
        // Option 2: Local wins (overwrite cloud)
        // Option 3: Merge changes (complex, field-by-field)
        // Option 4: Present to user for resolution
        
        // Example: Cloud wins
        try await docRef.setData(cloud)
    }
}
```

---

## 5. State Restoration

### Navigation State Preservation

```swift
class NavigationStateManager: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var navigationStack: [NavigationItem] = []
    
    private let stateKey = "navigationState"
    
    init() {
        restoreNavigationState()
    }
    
    func saveNavigationState() {
        let state = NavigationState(
            selectedTab: selectedTab,
            navigationStack: navigationStack
        )
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: stateKey)
        }
    }
    
    func restoreNavigationState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(NavigationState.self, from: data) else { return }
        
        selectedTab = state.selectedTab
        navigationStack = state.navigationStack
    }
}

struct NavigationState: Codable {
    let selectedTab: Int
    let navigationStack: [NavigationItem]
}

enum NavigationItem: Codable {
    case recipeDetail(recipeId: Int)
    case mealPlanDetail(planId: String)
    case profileSettings
    case searchResults(query: String)
    
    // Implement Codable manually for enum with associated values
    enum CodingKeys: String, CodingKey {
        case type, recipeId, planId, query
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "recipeDetail":
            let id = try container.decode(Int.self, forKey: .recipeId)
            self = .recipeDetail(recipeId: id)
        case "mealPlanDetail":
            let id = try container.decode(String.self, forKey: .planId)
            self = .mealPlanDetail(planId: id)
        case "profileSettings":
            self = .profileSettings
        case "searchResults":
            let query = try container.decode(String.self, forKey: .query)
            self = .searchResults(query: query)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Unknown navigation item type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .recipeDetail(let recipeId):
            try container.encode("recipeDetail", forKey: .type)
            try container.encode(recipeId, forKey: .recipeId)
        case .mealPlanDetail(let planId):
            try container.encode("mealPlanDetail", forKey: .type)
            try container.encode(planId, forKey: .planId)
        case .profileSettings:
            try container.encode("profileSettings", forKey: .type)
        case .searchResults(let query):
            try container.encode("searchResults", forKey: .type)
            try container.encode(query, forKey: .query)
        }
    }
}
```

---

## 6. AI Context Implementation

### User Behavior Tracking

```swift
class UserBehaviorTracker: ObservableObject {
    private let contextKey = "userBehaviorContext"
    
    @Published var interactionHistory: [UserInteraction] = []
    @Published var preferences: PreferenceScores = PreferenceScores()
    
    init() {
        loadBehaviorContext()
    }
    
    func trackInteraction(_ interaction: UserInteraction) {
        interactionHistory.append(interaction)
        updatePreferences(based: interaction)
        
        // Keep only recent interactions (last 30 days)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        interactionHistory = interactionHistory.filter { $0.timestamp > cutoffDate }
        
        saveBehaviorContext()
    }
    
    private func updatePreferences(based interaction: UserInteraction) {
        switch interaction.type {
        case .recipeSaved(let recipe):
            preferences.updateCuisineScore(recipe.cuisine, delta: 0.1)
            preferences.updateIngredientScores(recipe.ingredients, delta: 0.05)
        case .recipeSkipped(let recipe):
            preferences.updateCuisineScore(recipe.cuisine, delta: -0.05)
        case .recipePrepared(let recipe):
            preferences.updateCuisineScore(recipe.cuisine, delta: 0.2)
            preferences.updateIngredientScores(recipe.ingredients, delta: 0.1)
        case .mealPlanGenerated(let preferences):
            // Update based on meal plan preferences
            break
        }
    }
    
    private func saveBehaviorContext() {
        let context = BehaviorContext(
            interactionHistory: interactionHistory,
            preferences: preferences,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(context) {
            UserDefaults.standard.set(encoded, forKey: contextKey)
        }
    }
    
    private func loadBehaviorContext() {
        guard let data = UserDefaults.standard.data(forKey: contextKey),
              let context = try? JSONDecoder().decode(BehaviorContext.self, from: data) else { return }
        
        interactionHistory = context.interactionHistory
        preferences = context.preferences
    }
}

struct UserInteraction: Codable {
    let id: UUID = UUID()
    let timestamp: Date
    let type: InteractionType
    
    enum InteractionType: Codable {
        case recipeSaved(Recipe)
        case recipeSkipped(Recipe)
        case recipePrepared(Recipe)
        case mealPlanGenerated(UserPreferences)
        case searchPerformed(query: String, results: Int)
    }
}

struct PreferenceScores: Codable {
    private var cuisineScores: [String: Double] = [:]
    private var ingredientScores: [String: Double] = [:]
    
    mutating func updateCuisineScore(_ cuisine: String, delta: Double) {
        cuisineScores[cuisine, default: 0.0] += delta
        cuisineScores[cuisine] = max(-1.0, min(1.0, cuisineScores[cuisine] ?? 0.0)) // Clamp between -1 and 1
    }
    
    mutating func updateIngredientScores(_ ingredients: [Ingredient], delta: Double) {
        for ingredient in ingredients {
            ingredientScores[ingredient.name, default: 0.0] += delta
            ingredientScores[ingredient.name] = max(-1.0, min(1.0, ingredientScores[ingredient.name] ?? 0.0))
        }
    }
    
    func getCuisineScore(_ cuisine: String) -> Double {
        return cuisineScores[cuisine] ?? 0.0
    }
    
    func getIngredientScore(_ ingredient: String) -> Double {
        return ingredientScores[ingredient] ?? 0.0
    }
}

struct BehaviorContext: Codable {
    let interactionHistory: [UserInteraction]
    let preferences: PreferenceScores
    let lastUpdated: Date
}
```

---

## 7. Error Context and Recovery

### Resilient Context Saving

```swift
class ResilientContextManager {
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    func saveContextWithRetry<T: Codable>(_ context: T, key: String) async {
        var attempt = 0
        
        while attempt < maxRetries {
            do {
                try await saveContext(context, key: key)
                return // Success, exit retry loop
            } catch {
                attempt += 1
                print("Context save attempt \(attempt) failed: \(error)")
                
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt) * 1_000_000_000))
                } else {
                    // Final attempt failed, log error and potentially show user notification
                    await handleContextSaveFailure(context: context, key: key, error: error)
                }
            }
        }
    }
    
    private func saveContext<T: Codable>(_ context: T, key: String) async throws {
        let data = try JSONEncoder().encode(context)
        
        // Try different storage mechanisms in order of preference
        if await trySecureStorage(data: data, key: key) {
            return
        } else if tryUserDefaults(data: data, key: key) {
            return
        } else if await tryDocumentsDirectory(data: data, key: key) {
            return
        } else {
            throw ContextSaveError.allStorageFailed
        }
    }
    
    private func trySecureStorage(data: Data, key: String) async -> Bool {
        // Attempt to save to Keychain for sensitive data
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func tryUserDefaults(data: Data, key: String) -> Bool {
        UserDefaults.standard.set(data, forKey: key)
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    private func tryDocumentsDirectory(data: Data, key: String) async -> Bool {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                           in: .userDomainMask).first else {
            return false
        }
        
        let fileURL = documentsPath.appendingPathComponent("\(key).context")
        
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            return false
        }
    }
    
    private func handleContextSaveFailure<T: Codable>(context: T, key: String, error: Error) async {
        // Log to crash reporting service
        print("CRITICAL: Context save failed for key '\(key)': \(error)")
        
        // Potentially show user notification about data loss risk
        await MainActor.run {
            NotificationCenter.default.post(
                name: .contextSaveFailure,
                object: nil,
                userInfo: ["key": key, "error": error]
            )
        }
    }
}

enum ContextSaveError: Error {
    case allStorageFailed
    case dataCorrupted
    case insufficientSpace
}

extension Notification.Name {
    static let contextSaveFailure = Notification.Name("contextSaveFailure")
}
```

---

## 8. Testing Context Saving

### Unit Test Examples

```swift
import XCTest
@testable import Crookey

class ContextSavingTests: XCTestCase {
    var persistenceManager: PersistenceManager!
    var settingsManager: SettingsManager!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory store for testing
        persistenceManager = PersistenceManager(inMemory: true)
        settingsManager = SettingsManager()
    }
    
    func testRecipeContextSaving() {
        // Given
        let recipe = Recipe(
            id: 123,
            title: "Test Recipe",
            readyInMinutes: 30,
            servings: 4,
            image: "test.jpg",
            summary: "A test recipe",
            instructions: "Test instructions",
            healthScore: 85.0,
            diets: ["vegetarian"],
            ingredients: []
        )
        
        // When
        persistenceManager.saveRecipe(recipe)
        
        // Then
        let savedRecipes = persistenceManager.fetchSavedRecipes()
        XCTAssertEqual(savedRecipes.count, 1)
        XCTAssertEqual(savedRecipes.first?.title, "Test Recipe")
    }
    
    func testSettingsContextPersistence() {
        // Given
        var settings = AppSettings.default
        settings.appearance.colorScheme = .dark
        settings.notifications.dailyRecipeEnabled = false
        
        // When
        settingsManager.settings = settings
        
        // Create new instance to test persistence
        let newSettingsManager = SettingsManager()
        
        // Then
        XCTAssertEqual(newSettingsManager.settings.appearance.colorScheme, .dark)
        XCTAssertFalse(newSettingsManager.settings.notifications.dailyRecipeEnabled)
    }
    
    func testBehaviorContextTracking() {
        // Given
        let tracker = UserBehaviorTracker()
        let recipe = Recipe(id: 1, title: "Test", readyInMinutes: 30, servings: 2, 
                           image: "", summary: "", instructions: nil, healthScore: nil, 
                           diets: nil, ingredients: nil)
        
        // When
        tracker.trackInteraction(UserInteraction(
            timestamp: Date(),
            type: .recipeSaved(recipe)
        ))
        
        // Then
        XCTAssertEqual(tracker.interactionHistory.count, 1)
    }
}

class SyncContextTests: XCTestCase {
    func testSyncConflictResolution() async throws {
        // Given
        let syncService = SyncService(userId: "test-user")
        let localRecipe = SyncableRecipe(
            id: "recipe-123",
            lastModified: Date().addingTimeInterval(-100), // Older
            syncStatus: .pending,
            title: "Local Version",
            ingredients: [],
            instructions: "Local instructions"
        )
        
        // Mock cloud data (newer)
        let cloudData: [String: Any] = [
            "id": "recipe-123",
            "lastModified": Timestamp(date: Date()),
            "title": "Cloud Version",
            "ingredients": [],
            "instructions": "Cloud instructions"
        ]
        
        // When & Then
        // Test that cloud version wins in conflict resolution
        // (Implementation would depend on your specific conflict resolution strategy)
    }
}
```

---

## 9. Performance Optimization

### Batched Context Operations

```swift
class BatchedContextManager {
    private var pendingOperations: [ContextOperation] = []
    private let batchSize = 10
    private var batchTimer: Timer?
    
    func queueContextOperation(_ operation: ContextOperation) {
        pendingOperations.append(operation)
        
        if pendingOperations.count >= batchSize {
            processBatch()
        } else {
            scheduleBatchProcessing()
        }
    }
    
    private func scheduleBatchProcessing() {
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            self.processBatch()
        }
    }
    
    private func processBatch() {
        guard !pendingOperations.isEmpty else { return }
        
        let batch = Array(pendingOperations.prefix(batchSize))
        pendingOperations.removeFirst(min(batchSize, pendingOperations.count))
        
        Task {
            await processBatchOperations(batch)
        }
    }
    
    private func processBatchOperations(_ operations: [ContextOperation]) async {
        for operation in operations {
            do {
                try await operation.execute()
            } catch {
                print("Batch operation failed: \(error)")
                // Could implement retry logic here
            }
        }
    }
}

protocol ContextOperation {
    func execute() async throws
}

struct SaveRecipeOperation: ContextOperation {
    let recipe: Recipe
    
    func execute() async throws {
        PersistenceManager.shared.saveRecipe(recipe)
    }
}

struct SyncUserDataOperation: ContextOperation {
    let userId: String
    
    func execute() async throws {
        let syncService = SyncService(userId: userId)
        try await syncService.syncUserData()
    }
}
```

---

## 10. Migration and Versioning

### Context Schema Migration

```swift
enum ContextVersion: Int, CaseIterable {
    case v1_0 = 1
    case v1_1 = 2
    case v2_0 = 3
    
    static var current: ContextVersion {
        return allCases.last!
    }
}

class ContextMigrationManager {
    func migrateContextIfNeeded() {
        let currentVersion = getCurrentContextVersion()
        let targetVersion = ContextVersion.current
        
        if currentVersion.rawValue < targetVersion.rawValue {
            performMigration(from: currentVersion, to: targetVersion)
        }
    }
    
    private func performMigration(from: ContextVersion, to: ContextVersion) {
        print("Migrating context from \(from) to \(to)")
        
        for version in ContextVersion.allCases {
            if version.rawValue > from.rawValue && version.rawValue <= to.rawValue {
                migrateToVersion(version)
            }
        }
        
        setCurrentContextVersion(to)
    }
    
    private func migrateToVersion(_ version: ContextVersion) {
        switch version {
        case .v1_0:
            break // Initial version, no migration needed
        case .v1_1:
            migrateToV1_1()
        case .v2_0:
            migrateToV2_0()
        }
    }
    
    private func migrateToV1_1() {
        // Add cooking settings to existing user preferences
        if let data = UserDefaults.standard.data(forKey: "app_settings"),
           var settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            
            // Initialize new cooking settings with defaults
            // settings.cooking = AppSettings.CookingSettings()
            
            if let encoded = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(encoded, forKey: "app_settings")
            }
        }
    }
    
    private fun migrateToV2_0() {
        // Migrate from UserDefaults to more secure storage for sensitive data
        // Move user behavior context to encrypted storage
        migrateBehaviorContextToSecureStorage()
    }
}
```

---

This implementation guide provides practical examples for working with the Crookey context saving system. Each pattern can be adapted and extended based on specific feature requirements while maintaining consistency with the overall architecture.