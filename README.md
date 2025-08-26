# 🍳 Crookey - iOS Recipe and Food Analysis App

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15.4+-blue.svg)](https://developer.apple.com/xcode/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Crookey is a comprehensive iOS application that combines recipe management, food analysis, and meal planning using modern Swift and SwiftUI. The app features advanced food scanning capabilities, personalized recipe recommendations, and seamless integration with health tracking platforms.

## ✨ Features

### 🔍 **Food Scanning & Analysis**
- AI-powered food recognition using Vision framework
- Real-time nutritional analysis and freshness detection
- Ingredient identification with confidence scoring
- Camera integration with photo library support

### 📱 **Recipe Management**
- Extensive recipe discovery with advanced search
- Personalized recommendations based on dietary preferences
- Save favorite recipes with offline access
- Interactive cooking mode with step-by-step guidance
- Social sharing and community features

### 🥗 **Health & Nutrition**
- HealthKit integration for nutrition tracking
- Dietary restriction and allergy management
- Calorie and macro tracking
- Wellness insights and progress monitoring

### 🛒 **Meal Planning**
- Weekly meal planning with shopping list generation
- Inventory management and expiration tracking
- Smart grocery recommendations
- Budget tracking and cost analysis

### 🎨 **Modern UI/UX**
- Native SwiftUI interface with iOS design guidelines
- Dark mode support with adaptive theming
- Accessibility features (VoiceOver, Dynamic Type)
- Smooth animations and responsive design

## 🏗️ Architecture

Crookey follows modern iOS development patterns:

- **SwiftUI**: Declarative UI framework for all interfaces
- **MVVM Pattern**: Clean separation of concerns
- **Core Data**: Local data persistence with CloudKit sync
- **Combine**: Reactive programming for data binding
- **Async/Await**: Modern concurrency for API calls
- **Vision Framework**: ML-powered image analysis

## 📱 Requirements

- **iOS 15.0+**
- **Xcode 15.4+**
- **Swift 5.9+**
- **Apple Developer Account** (for device testing)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/kakashi3lite/Crookey.git
cd Crookey
```

### 2. Setup Development Environment
```bash
./setup.sh
```

### 3. Open in Xcode
```bash
make open
```

### 4. Configure Team Settings
- Open project settings in Xcode
- Select your Apple Developer Team
- Update bundle identifier if needed

### 5. Build and Run
```bash
make dev  # Lint, build, and test
# Or press ⌘+R in Xcode
```

## 🛠️ Development Workflow

### Available Commands
```bash
# Development
make dev           # Quick development workflow (lint, build, test)
make build         # Build the project
make test          # Run all tests
make clean         # Clean build artifacts

# Code Quality
make lint          # Run SwiftLint
make format        # Format code with SwiftFormat
make analyze       # Run static analysis

# Testing
make test-unit     # Run unit tests only
make test-ui       # Run UI tests only
make test-coverage # Generate coverage report

# Utilities
make open          # Open project in Xcode
make simulator     # Open iOS Simulator
make devices       # List available simulators
```

### Git Hooks
Automatic quality checks are enabled:
- **Pre-commit**: SwiftLint validation
- **Pre-push**: Unit test execution

## 🧪 Testing

The project includes comprehensive testing:

### Unit Tests (`CrookeyTests/`)
- Model validation and business logic
- Service layer testing
- Utility function verification

### UI Tests (`CrookeyUITests/`)
- End-to-end user flows
- Multi-device compatibility
- Accessibility compliance

### Test Plans
- **UnitTests.xctestplan**: Focused unit testing
- **UITests.xctestplan**: Cross-device UI testing
- **AccessibilityTests.xctestplan**: Accessibility validation

Run specific test suites:
```bash
xcodebuild test -scheme Crookey -testPlan UnitTests
xcodebuild test -scheme Crookey -testPlan UITests
```

## 🔄 CI/CD with Xcode Cloud

Crookey uses Xcode Cloud for automated CI/CD:

### Workflows
- **Development**: Feature branch validation
- **CI**: Main branch testing and analysis
- **Release**: TestFlight deployment

### Automated Checks
- ✅ SwiftLint code quality
- ✅ SwiftFormat style consistency
- ✅ Unit and UI test execution
- ✅ Multi-device compatibility
- ✅ Accessibility compliance
- ✅ Code coverage reporting

### Deployment
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Automatically builds and deploys to TestFlight.

## 📁 Project Structure

```
Crookey/
├── App/                          # App lifecycle and main entry point
│   ├── Models/                   # Data models and Core Data entities
│   ├── Services/                 # Business logic and API services
│   └── ViewModels/              # SwiftUI view models (MVVM)
├── Core/                        # Core functionality
│   ├── Config/                  # App configuration
│   ├── Network/                 # Networking layer
│   └── Storage/                 # Data persistence
├── Features/                    # Feature-based organization
│   ├── FoodScanner/            # Food scanning and analysis
│   ├── MealPlanning/           # Meal planning features
│   ├── Profile/                # User profile and settings
│   ├── Recipe/                 # Recipe management
│   ├── Search/                 # Recipe search functionality
│   └── Social/                 # Social features and sharing
├── UI/                         # User interface components
│   ├── Components/             # Reusable UI components
│   ├── Theme/                  # App theming and styling
│   └── Views/                  # Screen-level views
├── Services/                   # App-wide services
├── Tests/                      # Unit and UI tests
└── Resources/                  # Assets, localizations, etc.
```

## 🎯 Code Quality

### SwiftLint Configuration
- 50+ enabled rules for consistent code style
- Custom rules for SwiftUI best practices
- Enforced file headers and documentation

### SwiftFormat Configuration
- Automatic code formatting
- Consistent indentation and spacing
- Import organization and cleanup

### Coverage Goals
- **Unit Tests**: >80% code coverage
- **Critical Paths**: 100% coverage
- **UI Tests**: Core user flows

## 🔐 Security & Privacy

- **Privacy First**: Minimal data collection
- **Local Processing**: Food analysis on-device
- **Secure API**: HTTPS-only communications
- **Data Encryption**: Core Data encryption
- **Permission Management**: Granular privacy controls

## 🌍 Localization

Currently supporting:
- English (Base)
- *Additional languages planned*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow Swift style guidelines
- Include unit tests for new features
- Update documentation as needed
- Ensure accessibility compliance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- **Swanand Tanavade** - Lead Developer

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/kakashi3lite/Crookey/issues)
- **Documentation**: [Wiki](https://github.com/kakashi3lite/Crookey/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/kakashi3lite/Crookey/discussions)

## 🚀 Roadmap

### Version 1.0
- [x] Core recipe management
- [x] Food scanning functionality
- [x] Basic meal planning
- [x] Health integration
- [x] Xcode Cloud CI/CD

### Version 1.1 (Planned)
- [ ] Advanced meal planning
- [ ] Social features expansion
- [ ] Offline recipe storage
- [ ] Apple Watch companion app

### Version 2.0 (Future)
- [ ] AR food scanning
- [ ] Voice recipe instructions
- [ ] Smart kitchen integration
- [ ] Multi-language support

---

Made with ❤️ for iOS developers and food enthusiasts.