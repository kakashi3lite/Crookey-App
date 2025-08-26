# Xcode Cloud Setup Guide for Crookey

This document provides a comprehensive guide for setting up and using Xcode Cloud with the Crookey iOS application.

## Overview

Crookey is now configured with a complete Xcode Cloud CI/CD pipeline that includes:
- Continuous Integration for all branches
- Automated testing (Unit, UI, and Accessibility)
- Code quality checks (SwiftLint, SwiftFormat)
- Automated deployment to TestFlight
- Multi-device testing

## Project Structure

### Xcode Cloud Workflows

The project includes three main workflows located in `.xcode-cloud/workflows/`:

1. **Development Workflow** (`development.yml`)
   - **Triggers**: Feature branches, hotfix branches, pull requests
   - **Purpose**: Validates code quality and runs comprehensive tests
   - **Features**:
     - SwiftLint code linting
     - SwiftFormat code formatting checks
     - Multi-device testing (iPhone & iPad)
     - Accessibility testing
     - Code coverage reporting

2. **CI Workflow** (`ci.yml`)
   - **Triggers**: Main, develop branches, and all pull requests
   - **Purpose**: Core continuous integration testing
   - **Features**:
     - Build validation
     - Unit and UI testing
     - Static code analysis
     - Code coverage reporting

3. **Release Workflow** (`release.yml`)
   - **Triggers**: Release tags (v*), release branches, manual main branch builds
   - **Purpose**: Production deployment and distribution
   - **Features**:
     - Automatic build number incrementation
     - Production build creation
     - TestFlight deployment
     - Archive generation

### Test Configuration

#### Test Plans
Located in `Crookey.xcodeproj/xcshareddata/xctestplans/`:
- **UnitTests.xctestplan**: Isolated unit tests with code coverage
- **UITests.xctestplan**: User interface testing across multiple devices
- **AccessibilityTests.xctestplan**: Accessibility compliance testing

#### Test Targets
- **CrookeyTests**: Unit tests for business logic, models, and services
- **CrookeyUITests**: End-to-end user interface testing

### Code Quality Configuration

#### SwiftLint (`.swiftlint.yml`)
- **Rules**: 50+ enabled rules for code quality
- **Line Length**: 120 characters (warning), 150 (error)
- **File Length**: 400 lines (warning), 500 (error)
- **Custom Rules**: Tailored for SwiftUI and modern Swift practices
- **File Headers**: Enforces consistent file header format

#### SwiftFormat (`.swiftformat`)
- **Indentation**: 4 spaces
- **Import Organization**: Alphabetical with testable imports at bottom
- **Code Style**: Modern Swift 5.9+ conventions
- **Self Usage**: Automatic removal where not required

## Getting Started

### Prerequisites

1. **Apple Developer Account**: Required for code signing and TestFlight distribution
2. **Xcode 15.4+**: Latest stable version recommended
3. **GitHub Repository**: Connected to Xcode Cloud
4. **Team ID**: Your Apple Developer Team ID

### Initial Setup

1. **Configure Apple Developer Account**:
   ```bash
   # Set your team ID in environment variables
   export DEVELOPMENT_TEAM_ID="YOUR_TEAM_ID"
   ```

2. **Update Bundle Identifier**:
   - Update `PRODUCT_BUNDLE_IDENTIFIER` in project settings
   - Ensure it matches your App Store Connect app identifier

3. **Configure Code Signing**:
   - Use Automatic code signing for simplicity
   - Ensure certificates are available in your developer account

4. **Set up Environment Variables** in Xcode Cloud:
   - `DEVELOPMENT_TEAM_ID`: Your Apple Developer Team ID
   - `APPLE_ID_USERNAME`: Your Apple ID email
   - `APPLE_ID_PASSWORD`: App-specific password

### Workflow Configuration

#### Environment Variables Required:
- `DEVELOPMENT_TEAM_ID`: Apple Developer Team ID
- `APPLE_ID_USERNAME`: Apple ID for App Store uploads
- `APPLE_ID_PASSWORD`: App-specific password
- `CI_BUILD_NUMBER`: Auto-provided by Xcode Cloud

#### Build Settings:
- **iOS Deployment Target**: iOS 15.0+
- **Swift Version**: 5.9
- **Code Signing**: Automatic
- **Bitcode**: Disabled (deprecated)

## Usage

### Development Workflow

1. **Feature Development**:
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git push origin feature/new-feature
   ```
   - Automatically triggers development workflow
   - Runs linting, formatting checks, and tests

2. **Pull Requests**:
   - Create PR to `develop` or `main`
   - CI workflow validates all changes
   - Required status checks ensure quality

3. **Code Quality**:
   - SwiftLint runs automatically on all commits
   - Failed linting prevents merge
   - Format issues are highlighted

### Testing

#### Local Testing:
```bash
# Run unit tests
xcodebuild test -scheme Crookey -destination "platform=iOS Simulator,name=iPhone 15,OS=17.0" -testPlan UnitTests

# Run UI tests
xcodebuild test -scheme Crookey -destination "platform=iOS Simulator,name=iPhone 15,OS=17.0" -testPlan UITests

# Code coverage
xcodebuild test -scheme Crookey -destination "platform=iOS Simulator,name=iPhone 15,OS=17.0" -enableCodeCoverage YES
```

#### Xcode Cloud Testing:
- Tests run automatically on every commit
- Multi-device testing ensures compatibility
- Coverage reports generated automatically

### Deployment

#### TestFlight Deployment:
1. **Tag Release**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Monitor Build**:
   - Check Xcode Cloud dashboard
   - Build automatically deploys to TestFlight
   - Testers notified automatically

#### Manual Deployment:
1. Push to `main` branch
2. Manually trigger release workflow in Xcode Cloud
3. Monitor progress in Xcode or developer portal

## Monitoring and Maintenance

### Build Monitoring
- **Xcode Cloud Dashboard**: Monitor all builds and workflows
- **Notifications**: Configure team notifications for build status
- **Logs**: Access detailed build logs for debugging

### Performance Tracking
- **Build Times**: Monitor CI performance
- **Test Execution**: Track test suite performance
- **Coverage Reports**: Maintain code coverage standards

### Troubleshooting

#### Common Issues:

1. **Code Signing Failures**:
   - Verify Team ID in environment variables
   - Check certificate expiration
   - Ensure bundle identifier matches App Store Connect

2. **Test Failures**:
   - Check simulator availability
   - Verify test plan configuration
   - Review accessibility compliance

3. **Linting Failures**:
   - Run SwiftLint locally: `swiftlint --fix`
   - Check `.swiftlint.yml` configuration
   - Review file headers and formatting

4. **Deployment Issues**:
   - Verify Apple ID credentials
   - Check App Store Connect configuration
   - Ensure app version/build number increment

## Best Practices

### Code Quality
- Run SwiftLint locally before committing
- Maintain consistent file headers
- Keep functions under 30 lines
- Aim for >80% code coverage

### Testing Strategy
- Write unit tests for all business logic
- Create UI tests for critical user flows
- Test accessibility on all new features
- Use test plans to organize test execution

### Deployment Strategy
- Use semantic versioning (v1.0.0)
- Test thoroughly before tagging releases
- Monitor TestFlight feedback
- Maintain release notes

### Security
- Never commit API keys or secrets
- Use environment variables for sensitive data
- Review code changes in pull requests
- Monitor for dependency vulnerabilities

## Advanced Configuration

### Custom Build Scripts
Add custom build phases in Xcode project settings:

```bash
# SwiftLint Build Phase
if command -v swiftlint >/dev/null 2>&1; then
    swiftlint
else
    echo "warning: SwiftLint not installed"
fi

# SwiftFormat Build Phase
if command -v swiftformat >/dev/null 2>&1; then
    swiftformat --lint .
else
    echo "warning: SwiftFormat not installed"
fi
```

### Dependencies Management
- Use Swift Package Manager for dependencies
- Pin specific versions for stability
- Regularly update dependencies
- Monitor for security updates

### Performance Optimization
- Profile app performance regularly
- Monitor build times and optimize
- Use test parallelization
- Implement efficient caching strategies

## Support and Resources

### Documentation
- [Xcode Cloud Documentation](https://developer.apple.com/xcode-cloud/)
- [App Store Connect Guide](https://developer.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

### Tools
- **Xcode 15.4+**: Primary development environment
- **SwiftLint**: Code linting and style enforcement
- **SwiftFormat**: Automatic code formatting
- **Instruments**: Performance profiling

### Community
- Apple Developer Forums
- Swift.org Community
- iOS Developer Slack channels
- Stack Overflow

---

This setup provides a robust, scalable CI/CD pipeline for the Crookey iOS application. The configuration supports modern development practices while ensuring high code quality and reliable deployments.