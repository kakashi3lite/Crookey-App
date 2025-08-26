#!/bin/bash

# Crookey iOS Development Setup Script
# This script sets up the local development environment for Crookey

echo "🚀 Setting up Crookey iOS Development Environment"
echo "================================================"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script requires macOS for iOS development"
    exit 1
fi

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is required but not installed. Please install from the App Store."
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew found: $(brew --version | head -n 1)"
fi

# Install SwiftLint
if ! command -v swiftlint &> /dev/null; then
    echo "📝 Installing SwiftLint..."
    brew install swiftlint
else
    echo "✅ SwiftLint found: $(swiftlint version)"
fi

# Install SwiftFormat
if ! command -v swiftformat &> /dev/null; then
    echo "🎨 Installing SwiftFormat..."
    brew install swiftformat
else
    echo "✅ SwiftFormat found: $(swiftformat --version)"
fi

# Install xcbeautify for better build output
if ! command -v xcbeautify &> /dev/null; then
    echo "✨ Installing xcbeautify..."
    brew install xcbeautify
else
    echo "✅ xcbeautify found"
fi

# Setup Git hooks (optional)
echo "🔧 Setting up Git hooks..."
if [ ! -d ".git/hooks" ]; then
    mkdir -p .git/hooks
fi

# Pre-commit hook for SwiftLint
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# SwiftLint pre-commit hook

if command -v swiftlint >/dev/null 2>&1; then
    swiftlint --strict
    if [ $? -ne 0 ]; then
        echo "SwiftLint failed. Please fix the issues before committing."
        exit 1
    fi
else
    echo "SwiftLint not installed. Please install it: brew install swiftlint"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit

# Pre-push hook for tests
cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
# Run tests before push

echo "Running tests before push..."

xcodebuild test \
    -scheme Crookey \
    -destination "platform=iOS Simulator,name=iPhone 15,OS=17.0" \
    -testPlan UnitTests \
    -quiet

if [ $? -ne 0 ]; then
    echo "Tests failed. Please fix the failing tests before pushing."
    exit 1
fi

echo "All tests passed! ✅"
EOF

chmod +x .git/hooks/pre-push

# Create local configuration files if they don't exist
if [ ! -f "Config.xcconfig" ]; then
    echo "⚙️ Creating local configuration file..."
    cat > Config.xcconfig << 'EOF'
// Local development configuration
// Copy this file and modify as needed for your local setup

DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.crookey
CODE_SIGN_STYLE = Automatic
EOF
fi

# Setup iOS Simulator
echo "📱 Setting up iOS Simulators..."
xcrun simctl list devices | grep -E "(iPhone 15|iPad Pro)" | head -2

# Final setup verification
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Update your Apple Developer Team ID in Config.xcconfig"
echo "2. Open Crookey.xcodeproj in Xcode"
echo "3. Select your development team in project settings"
echo "4. Build and run the project (⌘+R)"
echo ""
echo "Available commands:"
echo "• make lint      - Run SwiftLint"
echo "• make format    - Format code with SwiftFormat"
echo "• make test      - Run all tests"
echo "• make build     - Build the project"
echo ""
echo "Happy coding! 👨‍💻👩‍💻"