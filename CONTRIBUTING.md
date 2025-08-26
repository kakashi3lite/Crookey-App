# Contributing to Crookey

Thank you for your interest in contributing to Crookey! This document provides guidelines and information for contributors.

## 🎯 Getting Started

### Prerequisites
- macOS with Xcode 15.4+
- iOS development experience with Swift and SwiftUI
- Familiarity with Git and GitHub workflows

### Setup
1. Fork the repository
2. Clone your fork locally
3. Run the setup script: `./setup.sh`
4. Open the project: `make open`

## 🛠️ Development Process

### Branch Strategy
- **main**: Production-ready code
- **develop**: Integration branch for features
- **feature/***: New features and enhancements
- **hotfix/***: Critical bug fixes
- **release/***: Release preparation

### Workflow
1. Create a feature branch from `develop`
2. Make your changes following our coding standards
3. Add tests for new functionality
4. Run the full test suite: `make test`
5. Ensure code quality: `make lint`
6. Submit a pull request

## 📝 Coding Standards

### Swift Style Guide
We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### Code Organization
```swift
// MARK: - Properties
private var property: Type

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
}

// MARK: - Setup
private func setupUI() {
    // UI setup code
}

// MARK: - Actions
@IBAction private func buttonTapped() {
    // Action handling
}

// MARK: - Helper Methods
private func helperMethod() {
    // Helper implementation
}
```

#### SwiftUI Best Practices
```swift
struct ContentView: View {
    // MARK: - Properties
    @State private var isLoading = false
    @StateObject private var viewModel = ContentViewModel()
    
    // MARK: - Body
    var body: some View {
        VStack {
            if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Subviews
    private var loadingView: some View {
        ProgressView("Loading...")
    }
    
    private var contentView: some View {
        // Content implementation
    }
}
```

#### Naming Conventions
- Use descriptive names for variables, functions, and types
- Prefer full words over abbreviations
- Use camelCase for properties and methods
- Use PascalCase for types and protocols
- Use UPPER_CASE for constants

#### Documentation
```swift
/// Calculates the nutritional information for a given recipe
/// - Parameter recipe: The recipe to analyze
/// - Returns: Nutritional information including calories, protein, carbs, and fat
/// - Throws: `NutritionError.invalidIngredients` if ingredients are malformed
func calculateNutrition(for recipe: Recipe) throws -> NutritionalInfo {
    // Implementation
}
```

### Code Quality Tools

#### SwiftLint
Our SwiftLint configuration enforces:
- Line length: 120 characters (warning), 150 (error)
- File length: 400 lines (warning), 500 (error)
- Function body length: 30 lines (warning), 40 (error)
- Consistent file headers

Run locally:
```bash
make lint          # Check for issues
make lint-fix      # Auto-fix issues where possible
```

#### SwiftFormat
Automatic code formatting is enforced. Run:
```bash
make format        # Format all files
make format-check  # Check formatting without changes
```

## 🧪 Testing Guidelines

### Test Structure
```
CrookeyTests/
├── Models/           # Model tests
├── Services/         # Service layer tests
├── ViewModels/       # ViewModel tests
├── Utils/           # Utility tests
└── Mocks/           # Mock objects
```

### Writing Tests

#### Unit Tests
```swift
class RecipeServiceTests: XCTestCase {
    var sut: RecipeService!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = RecipeService(networkService: mockNetworkService)
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    func testFetchRecipes_WithValidData_ReturnsRecipes() throws {
        // Given
        let expectedRecipes = [Recipe.mock()]
        mockNetworkService.result = .success(expectedRecipes)
        
        // When
        let expectation = expectation(description: "Fetch recipes")
        var receivedRecipes: [Recipe]?
        
        sut.fetchRecipes { result in
            if case .success(let recipes) = result {
                receivedRecipes = recipes
            }
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedRecipes, expectedRecipes)
    }
}
```

#### UI Tests
```swift
class RecipeDiscoveryUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testRecipeDiscovery_TapRecipe_ShowsDetail() {
        // Given
        let recipesGrid = app.scrollViews["RecipesGrid"]
        let firstRecipe = recipesGrid.buttons.firstMatch
        
        // When
        firstRecipe.tap()
        
        // Then
        XCTAssertTrue(app.navigationBars["Recipe Detail"].exists)
    }
}
```

### Test Requirements
- All new features must include unit tests
- Critical user flows require UI tests
- Maintain >80% code coverage
- Test both success and failure scenarios
- Include accessibility tests for new UI components

### Running Tests
```bash
make test          # Run all tests
make test-unit     # Unit tests only
make test-ui       # UI tests only
make test-coverage # Generate coverage report
```

## 📱 UI/UX Guidelines

### Design Principles
- Follow Apple's Human Interface Guidelines
- Maintain consistency with iOS design patterns
- Prioritize accessibility and inclusive design
- Use system fonts, colors, and spacing

### SwiftUI Components
Create reusable components following this pattern:
```swift
struct CKButton: View {
    enum Style {
        case primary, secondary, destructive
    }
    
    let title: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(foregroundColor)
        }
        .buttonStyle(buttonStyle)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .accentColor
        case .destructive: return .white
        }
    }
    
    private var buttonStyle: some ButtonStyle {
        switch style {
        case .primary: return PrimaryButtonStyle()
        case .secondary: return SecondaryButtonStyle()
        case .destructive: return DestructiveButtonStyle()
        }
    }
}
```

### Accessibility
- Add accessibility labels and hints
- Support Dynamic Type
- Ensure VoiceOver compatibility
- Test with accessibility inspector

```swift
Button("Add Recipe") {
    addRecipe()
}
.accessibilityLabel("Add new recipe")
.accessibilityHint("Creates a new recipe entry")
```

## 🚀 Performance Guidelines

### Best Practices
- Use `@StateObject` for view model ownership
- Use `@ObservedObject` for passed-in models
- Minimize view updates with `@State` and `@Binding`
- Profile with Instruments regularly

### Memory Management
- Avoid retain cycles in closures
- Use weak/unowned references appropriately
- Cancel network requests when views disappear

### Network Optimization
- Cache images and data appropriately
- Use background queues for heavy operations
- Implement proper error handling

## 🔄 Pull Request Process

### Before Submitting
1. Ensure all tests pass: `make test`
2. Run code quality checks: `make lint`
3. Update documentation if needed
4. Add entry to CHANGELOG.md if applicable

### PR Description Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Include screenshots or GIFs]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Documentation updated
```

### Review Process
1. Automated checks must pass (CI/CD)
2. Code review by project maintainer
3. Address feedback and update PR
4. Final approval and merge

## 🐛 Bug Reports

### Before Reporting
1. Check existing issues
2. Try to reproduce consistently
3. Test on latest version

### Bug Report Template
```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Bug occurs

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- iOS version:
- Device model:
- App version:

## Screenshots
[If applicable]

## Additional Context
Any other relevant information
```

## 💡 Feature Requests

### Proposing Features
1. Check existing feature requests
2. Discuss in GitHub Discussions first
3. Create detailed issue with use cases

### Feature Request Template
```markdown
## Feature Description
Brief description of the feature

## Problem Statement
What problem does this solve?

## Proposed Solution
How should this work?

## Alternatives Considered
Other approaches considered

## Use Cases
Specific scenarios where this helps

## Implementation Notes
Technical considerations (if any)
```

## 📚 Resources

### Documentation
- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Tools
- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [Xcode Cloud](https://developer.apple.com/xcode-cloud/)

### Learning Resources
- [Swift by Sundell](https://www.swiftbysundell.com)
- [Hacking with Swift](https://www.hackingwithswift.com)
- [WWDC Videos](https://developer.apple.com/videos/)

## 🙏 Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributor statistics

Thank you for contributing to Crookey! 🍳