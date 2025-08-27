# Context Saving Documentation - Crookey

## Overview

This document outlines the comprehensive context saving architecture for the Crookey cooking application. Context saving ensures user data persistence, state management, and seamless experience across app sessions, devices, and scenarios.

## Architecture Overview

The Crookey app implements a multi-layered context saving strategy:

1. **Local Persistence**: Core Data for structured data
2. **Settings Storage**: UserDefaults for application preferences
3. **Cloud Sync**: Firebase Firestore for cross-device synchronization
4. **State Management**: SwiftUI property wrappers for UI state
5. **AI Context**: Machine learning model states and user behavior patterns

---

## 1. Local Data Persistence

### Core Data Stack

**Location**: `Core/Storage/PersistenceManager.swift`

The app uses Core Data as its primary local persistence mechanism with the following entities:

#### Entity Schema

```xml
<!-- SavedRecipe Entity -->
<entity name="SavedRecipe">
    <attribute name="id" type="Integer 64"/>
    <attribute name="title" type="String"/>
    <attribute name="readyInMinutes" type="Integer 16"/>
    <attribute name="servings" type="Integer 16"/>
    <attribute name="image" type="String" optional="YES"/>
    <attribute name="summary" type="String" optional="YES"/>
    <attribute name="instructions" type="String" optional="YES"/>
    <attribute name="dateAdded" type="Date" optional="YES"/>
    <relationship name="ingredients" toMany="YES" destinationEntity="SavedIngredient"/>
</entity>

<!-- SavedIngredient Entity -->
<entity name="SavedIngredient">
    <attribute name="id" type="Integer 64"/>
    <attribute name="name" type="String"/>
    <attribute name="amount" type="Double"/>
    <attribute name="unit" type="String"/>
    <attribute name="image" type="String" optional="YES"/>
    <relationship name="recipe" maxCount="1" destinationEntity="SavedRecipe"/>
</entity>

<!-- ShoppingListItem Entity -->
<entity name="ShoppingListItem">
    <attribute name="id" type="Integer 64"/>
    <attribute name="name" type="String"/>
    <attribute name="amount" type="Double"/>
    <attribute name="unit" type="String"/>
    <attribute name="dateAdded" type="Date"/>
    <attribute name="isChecked" type="Boolean"/>
</entity>
```

#### Operations

- **Recipe Persistence**: Recipes with ingredients are saved as complete entities
- **Shopping List**: Items can be added, toggled, and sorted by completion status
- **Data Integrity**: Cascading deletes maintain referential integrity

---

## 2. Application Settings & Preferences

### Settings Manager

**Location**: `Services/SettingsManager.swift`

Uses JSON encoding to UserDefaults for structured settings persistence:

```swift
struct AppSettings: Codable {
    var appearance: AppearanceSettings
    var notifications: NotificationSettings
    var privacy: PrivacySettings
    var storage: StorageSettings
}
```

#### Settings Categories

1. **Appearance Settings**
   - Color scheme (system/light/dark)
   - Accent color preferences
   - Font size preferences

2. **Notification Settings**
   - Daily recipe notifications
   - Meal planning reminders
   - Cooking timers and alerts
   - Shopping list reminders

3. **Privacy Settings**
   - Data sharing preferences
   - Analytics opt-in/out
   - Location service permissions

4. **Storage Settings**
   - Local vs cloud preferences
   - Cache management settings
   - Sync frequency preferences

---

## 3. User Authentication & Profile Context

### Authentication Service

**Location**: `Services/AuthenticationService.swift`

#### Firebase Integration

- **User Authentication**: Email/password and OAuth providers
- **Profile Storage**: Firestore document per user
- **Session Management**: Automatic token refresh and state persistence

#### User Profile Structure

```swift
struct UserProfile: Codable {
    let id: String
    let email: String
    let name: String
    let createdAt: Date
    let preferences: UserPreferences
    
    // Additional fields for context saving
    var lastActiveDate: Date?
    var deviceTokens: [String]  // For push notifications
    var syncStatus: SyncStatus
}
```

---

## 4. AI & Machine Learning Context

### Recommendations Engine

**Location**: `Services/RecommendationsEngine.swift`

#### Context Factors

1. **User Behavioral Context**
   - Recipe interaction history
   - Cooking frequency patterns
   - Preferred meal times
   - Seasonal preferences

2. **Environmental Context**
   - Current season for ingredient suggestions
   - Time of day for meal type recommendations
   - Location-based cuisine preferences

3. **Learning Context**
   - ML model weights and parameters
   - User preference scores
   - Recommendation success rates

#### Context Preservation

```swift
private struct UserContextWeights {
    static let userPreference = 0.4      // Historical likes/dislikes
    static let previousInteractions = 0.3 // Recipe engagement
    static let seasonality = 0.2         // Time-based preferences
    static let timeOfDay = 0.1          // Current meal context
}
```

### Food Scanner Context

**Location**: `App/Services/FoodScannerService.swift`

#### ML Model Context

- **Vision Model**: Core ML food classification model
- **Confidence Tracking**: Historical accuracy for model improvement
- **Classification History**: User corrections and feedback

#### Context Data

```swift
struct FoodAnalysisContext {
    let timestamp: Date
    let confidence: Double
    let classification: FoodClassification
    let userCorrection: FoodClassification?  // If user corrected AI
    let nutritionalAccuracy: Double?         // User-verified nutrition info
}
```

---

## 5. Cloud Synchronization Context

### Sync Service

**Location**: `Services/SyncService.swift`

#### Synchronization Strategy

1. **Real-time Sync**: Firestore listeners for immediate updates
2. **Conflict Resolution**: Last-write-wins with timestamp comparison
3. **Offline Support**: Local changes queued for sync when online
4. **Selective Sync**: User can choose what data to sync

#### Sync Context Structure

```swift
struct SyncContext {
    var lastSyncTimestamp: Date
    var pendingOperations: [SyncOperation]
    var conflictResolution: ConflictStrategy
    var syncStatus: SyncStatus
    
    enum SyncOperation {
        case create(entity: Any, timestamp: Date)
        case update(entity: Any, timestamp: Date)
        case delete(entityId: String, timestamp: Date)
    }
}
```

---

## 6. Application State Management

### SwiftUI State Architecture

The app uses various SwiftUI property wrappers for state management:

#### Primary State Patterns

1. **@StateObject**: For view-owned observable objects
2. **@ObservedObject**: For externally-owned observable objects
3. **@Published**: For reactive data binding
4. **@AppStorage**: For simple UserDefaults-backed properties

#### Key ViewModels

- `RecipeViewModel`: Recipe browsing and interaction state
- `MealPlanningViewModel`: Meal plan generation and management
- `FoodScannerViewModel`: Camera and analysis state
- `SocialFeedViewModel`: Social interactions and posts
- `ProfileViewModel`: User profile and settings state

---

## 7. Session Context Preservation

### Application Lifecycle Management

#### Background/Foreground Transitions

```swift
// App lifecycle hooks for context saving
func sceneWillResignActive() {
    // Save current user context
    PersistenceManager.shared.saveContext()
    SettingsManager.shared.saveSettings()
    
    // Preserve current view state
    saveApplicationState()
}

func sceneDidBecomeActive() {
    // Restore user context
    loadApplicationState()
    
    // Refresh time-sensitive data
    refreshContextualData()
}
```

#### Deep Link Context

The app preserves navigation state for deep linking:

```swift
struct NavigationContext: Codable {
    var selectedTab: Int
    var navigationStack: [NavigationItem]
    var presentedModals: [ModalInfo]
    var searchContext: SearchState?
}
```

---

## 8. Privacy & Security Context

### Data Protection

1. **Sensitive Data Encryption**: Using iOS Keychain for sensitive preferences
2. **GDPR Compliance**: User consent tracking and data export capabilities
3. **Local Data Anonymization**: Removing PII from analytics data

### Security Context

```swift
struct SecurityContext {
    var biometricAuthEnabled: Bool
    var lastPasswordChange: Date?
    var loginAttempts: Int
    var suspiciousActivityDetected: Bool
    var dataEncryptionLevel: EncryptionLevel
}
```

---

## 9. Performance Context

### Caching Strategy

**Location**: Various ViewModels and Services

#### Cache Layers

1. **Image Cache**: Recipe and ingredient images
2. **API Response Cache**: Recipe search results
3. **ML Model Cache**: Pre-processed food classification results
4. **User Context Cache**: Frequently accessed preferences

#### Cache Invalidation

```swift
struct CacheContext {
    var imageCache: [String: Date]      // URL -> Last accessed
    var apiCache: [String: Date]        // Query -> Last fetched  
    var mlCache: [String: Date]         // Image hash -> Analysis date
    var maxCacheAge: TimeInterval = 86400 // 24 hours
}
```

---

## 10. Error Context & Recovery

### Error State Preservation

The app maintains error context for debugging and user experience:

```swift
struct ErrorContext {
    var lastError: AppError?
    var errorTimestamp: Date?
    var recoveryAttempts: Int
    var userReportedIssues: [UserReport]
    var networkStatus: NetworkStatus
}
```

### Recovery Strategies

1. **Automatic Recovery**: Retry failed operations with exponential backoff
2. **Manual Recovery**: User-initiated retry with context restoration
3. **Graceful Degradation**: Offline mode with local context preservation

---

## Implementation Guidelines

### 1. Context Saving Best Practices

- **Minimize Frequency**: Only save context when necessary
- **Batch Operations**: Group related context saves
- **Background Saving**: Use background queues for heavy operations
- **Version Compatibility**: Handle context schema migrations

### 2. Testing Context Saving

Create unit tests for:
- Context serialization/deserialization
- Migration between context versions
- Recovery from corrupted context
- Performance impact of context operations

### 3. Monitoring & Analytics

Track context saving metrics:
- Save operation success rates
- Context restoration times
- User preference accuracy
- ML model performance over time

---

## Future Enhancements

### Planned Context Improvements

1. **Advanced AI Context**: More sophisticated user behavior modeling
2. **Cross-Platform Context**: Context sharing between iOS and web versions
3. **Collaborative Context**: Shared contexts for family meal planning
4. **Predictive Context**: Proactive context preparation based on usage patterns

### Technical Debt

Areas for improvement:
- Unify context saving mechanisms across different services
- Implement more granular sync controls
- Add context compression for large datasets
- Improve offline context synchronization

---

## Conclusion

The Crookey app implements a comprehensive context saving system that ensures user data persistence, maintains application state, and provides seamless experiences across sessions and devices. The multi-layered approach balances performance, privacy, and user experience while providing robust data protection and synchronization capabilities.

For implementation details of specific components, refer to the individual service and model files referenced throughout this document.