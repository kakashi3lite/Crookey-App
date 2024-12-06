# Crookey - iOS Recipe and Food Analysis App 🧑‍🍳

Crookey is a comprehensive iOS application that combines recipe management, food analysis, and meal planning using modern Swift and SwiftUI.

## Features 🌟

### Core Features
- Recipe discovery with swipe-based interface
- Intelligent meal planning
- Food freshness detection using ML
- Personalized recipe recommendations
- Offline support with CoreData
- HealthKit integration for nutrition tracking

### Technical Features
- SwiftUI and Combine framework
- CoreData for persistence
- CoreML for food analysis
- HealthKit integration
- Firebase backend
- Clean Architecture

## Project Structure 📁

```
Crookey/
├── App/
│   ├── CrookeyApp.swift
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── Info.plist
│
├── Features/
│   ├── Recipe/
│   ├── FoodScanner/
│   ├── Search/
│   └── MealPlanning/
│
├── Core/
│   ├── Network/
│   ├── Storage/
│   └── Config/
│
├── Services/
├── Models/
└── UI/
```

## Requirements 📱

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager
- Active Apple Developer Account

## Installation 💻

1. Clone the repository
```bash
git clone https://github.com/kakashi3lite/Crookey-App.git
cd Crookey-App
```

2. Install dependencies
```bash
pod install
# or if using SPM, open the .xcodeproj file directly
```

3. Add required API keys in Config.swift:
```swift
struct APIConfig {
    static let spoonacularKey = "YOUR_SPOONACULAR_KEY"
}
```

4. Open Crookey.xcworkspace and run the project

## Configuration ⚙️

### Required API Keys
- Spoonacular API key for recipe data
- Firebase configuration

### Required Permissions
- Camera access for food scanning
- Photo library access
- HealthKit permissions

## Features Implementation Status 📋

### Completed ✅
- Basic app structure
- Core Data implementation
- Recipe service
- Authentication service
- Health tracking service
- Cache service
- Error handling

### In Progress 🚧
- ML model integration
- Social features
- Advanced recipe filtering
- Comprehensive testing

### Planned 📅
- Recipe sharing
- Advanced meal planning
- Nutrition analysis
- Shopping list optimization

## Architecture 🏗

The app follows Clean Architecture principles with MVVM pattern:
- Views (SwiftUI)
- ViewModels (Business Logic)
- Models (Data Layer)
- Services (Network/Local Data)

## Services 🔧

1. Recipe Service
   - Recipe fetching
   - Search functionality
   - Recommendations

2. Authentication Service
   - User management
   - Session handling

3. Health Service
   - HealthKit integration
   - Nutrition tracking

4. Cache Service
   - Offline support
   - Data persistence

## Contributing 🤝

1. Fork the project
2. Create your feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. Push to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request

## Testing 🧪

Run the tests using Xcode's Test Navigator (⌘U)

```bash
xcodebuild test -scheme Crookey -destination 'platform=iOS Simulator,name=iPhone 13'
```

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- [Spoonacular API](https://spoonacular.com/food-api) for recipe data
- [Firebase](https://firebase.google.com) for backend services
- Apple's CoreML and Vision frameworks

## Support 📱

For support, email support@crookey.app or open an issue in the repository.
