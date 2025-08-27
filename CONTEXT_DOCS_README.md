# Context Saving Documentation - Quick Reference

## Overview

This directory contains comprehensive documentation for the Crookey app's context saving system. The context saving architecture ensures user data persistence, application state management, and seamless user experiences across app sessions and devices.

## Documentation Files

### 📋 [CONTEXT_SAVING.md](./CONTEXT_SAVING.md)
**Comprehensive Architecture Overview**

This is the main documentation file that covers:
- Complete context saving architecture
- Data persistence strategies (Core Data, UserDefaults, Firebase)
- User authentication and profile management
- AI/ML context preservation
- Cloud synchronization
- Application state management
- Privacy and security considerations
- Performance optimization
- Future enhancement roadmap

**Best for**: Understanding the overall system, architectural decisions, and context saving strategies.

### 🛠 [CONTEXT_SAVING_IMPLEMENTATION.md](./CONTEXT_SAVING_IMPLEMENTATION.md)
**Developer Implementation Guide**

This file provides practical implementation examples and code patterns:
- Adding new persistent data models
- Creating context-aware ViewModels
- Implementing settings context
- Cloud sync implementation
- State restoration patterns
- AI context tracking
- Error handling and recovery
- Testing strategies
- Performance optimization techniques
- Migration and versioning

**Best for**: Developers implementing new features or modifying existing context saving functionality.

## Quick Start

### For New Developers
1. Read [CONTEXT_SAVING.md](./CONTEXT_SAVING.md) first to understand the architecture
2. Reference [CONTEXT_SAVING_IMPLEMENTATION.md](./CONTEXT_SAVING_IMPLEMENTATION.md) for implementation patterns
3. Look at existing code examples in the Services/ and ViewModels/ directories

### For Feature Development
1. Check the relevant sections in the implementation guide
2. Follow the established patterns for consistency
3. Test context saving/restoration scenarios
4. Update documentation if adding new context types

### For Bug Fixes
1. Identify which context layer is involved (local, cloud, state)
2. Check error handling patterns in the implementation guide
3. Verify context restoration works correctly
4. Test edge cases (app termination, network issues, etc.)

## Key Context Saving Components

### Core Services
- **PersistenceManager** (`Core/Storage/PersistenceManager.swift`) - Core Data operations
- **SettingsManager** (`Services/SettingsManager.swift`) - App preferences and settings
- **SyncService** (`Services/SyncService.swift`) - Cloud synchronization
- **AuthenticationService** (`Services/AuthenticationService.swift`) - User context and authentication

### ViewModels
- **RecipeViewModel** - Recipe browsing and interaction state
- **MealPlanningViewModel** - Meal plan generation and management  
- **FoodScannerViewModel** - Camera and food analysis state
- **SocialFeedViewModel** - Social interactions and posts

### AI/ML Context
- **RecommendationsEngine** (`Services/RecommendationsEngine.swift`) - User behavior and preferences
- **FoodScannerService** (`App/Services/FoodScannerService.swift`) - ML model context
- **UserBehaviorTracker** - User interaction patterns

## Testing Context Saving

### Test Categories
1. **Unit Tests**: Individual component context saving/loading
2. **Integration Tests**: Cross-component context synchronization  
3. **UI Tests**: State restoration after app lifecycle events
4. **Performance Tests**: Context operation impact on app performance

### Test Scenarios
- App launch with existing context
- Background/foreground transitions
- Network connectivity changes
- User authentication state changes
- Data migration between app versions

## Common Issues and Solutions

### Context Not Saving
- Check if proper save triggers are implemented
- Verify error handling doesn't silently fail
- Ensure background queue operations complete
- Test with device storage limitations

### Context Conflicts
- Review cloud sync conflict resolution
- Check timestamp comparison logic
- Verify user preference for conflict handling
- Test concurrent modification scenarios

### Performance Issues
- Review batching strategies
- Check for unnecessary context saves
- Profile context save/load operations
- Consider lazy loading for large contexts

### Migration Issues  
- Test migration between all supported versions
- Verify backward compatibility
- Check for data loss during migration
- Test edge cases (corrupted context, partial migration)

## Architecture Principles

### Context Saving Best Practices
1. **Minimize Frequency**: Save context only when necessary
2. **Batch Operations**: Group related context saves
3. **Error Recovery**: Handle save failures gracefully
4. **User Privacy**: Encrypt sensitive context data
5. **Performance**: Use background queues for heavy operations
6. **Testing**: Verify context restoration in all scenarios

### Design Patterns Used
- **Repository Pattern**: Centralized data access through PersistenceManager
- **Observer Pattern**: SwiftUI property wrappers for reactive updates
- **Strategy Pattern**: Different storage mechanisms (Core Data, UserDefaults, Keychain)
- **Command Pattern**: Queued context operations for batching
- **Singleton Pattern**: Shared managers for cross-app context access

## Contributing

When modifying context saving functionality:

1. **Update Documentation**: Keep both documentation files current
2. **Add Tests**: Include tests for new context saving scenarios
3. **Follow Patterns**: Use established patterns for consistency
4. **Consider Privacy**: Ensure new context respects user privacy settings
5. **Performance Impact**: Measure and minimize performance impact
6. **Migration Path**: Consider how changes affect existing user data

## Related Resources

- [Apple Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [Firebase iOS Documentation](https://firebase.google.com/docs/ios)
- [SwiftUI Data and Storage](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [iOS App Lifecycle](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle)

---

For questions or clarifications about context saving implementation, refer to the detailed documentation files or consult the development team.