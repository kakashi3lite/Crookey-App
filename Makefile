# Makefile for Crookey iOS Development
# Usage: make [target]

# Variables
SCHEME = Crookey
DESTINATION = "platform=iOS Simulator,name=iPhone 15,OS=17.0"
CONFIGURATION = Debug
ARCHIVE_PATH = build/Crookey.xcarchive
EXPORT_PATH = build/
TEST_PLAN_UNIT = UnitTests
TEST_PLAN_UI = UITests

# Default target
.DEFAULT_GOAL := help

# Help target
help: ## Show this help message
	@echo "Crookey iOS Development Commands"
	@echo "================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Setup development environment
	@echo "🚀 Setting up development environment..."
	@./setup.sh

# Code Quality
lint: ## Run SwiftLint
	@echo "📝 Running SwiftLint..."
	@swiftlint --reporter xcode

lint-fix: ## Fix SwiftLint issues automatically
	@echo "🔧 Fixing SwiftLint issues..."
	@swiftlint --fix

format: ## Format code with SwiftFormat
	@echo "🎨 Formatting code..."
	@swiftformat .

format-check: ## Check code formatting
	@echo "👁️ Checking code format..."
	@swiftformat --lint .

# Building
build: ## Build the project for Debug
	@echo "🔨 Building project..."
	@xcodebuild build \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-quiet | xcbeautify

build-release: ## Build the project for Release
	@echo "🔨 Building project (Release)..."
	@xcodebuild build \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration Release \
		-quiet | xcbeautify

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@xcodebuild clean \
		-scheme $(SCHEME) \
		-quiet
	@rm -rf build/
	@rm -rf DerivedData/

# Testing
test: ## Run all tests
	@echo "🧪 Running all tests..."
	@xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-enableCodeCoverage YES \
		-quiet | xcbeautify

test-unit: ## Run unit tests only
	@echo "🔬 Running unit tests..."
	@xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-testPlan $(TEST_PLAN_UNIT) \
		-enableCodeCoverage YES \
		-quiet | xcbeautify

test-ui: ## Run UI tests only
	@echo "📱 Running UI tests..."
	@xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-testPlan $(TEST_PLAN_UI) \
		-quiet | xcbeautify

test-coverage: ## Generate code coverage report
	@echo "📊 Generating coverage report..."
	@xcodebuild test \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-enableCodeCoverage YES \
		-derivedDataPath DerivedData/ \
		-quiet | xcbeautify
	@echo "Coverage report available in DerivedData/Logs/Test/"

# Analysis
analyze: ## Run static analysis
	@echo "🔍 Running static analysis..."
	@xcodebuild analyze \
		-scheme $(SCHEME) \
		-destination $(DESTINATION) \
		-configuration $(CONFIGURATION) \
		-quiet | xcbeautify

# Archiving and Export
archive: ## Create archive for distribution
	@echo "📦 Creating archive..."
	@mkdir -p build
	@xcodebuild archive \
		-scheme $(SCHEME) \
		-destination "generic/platform=iOS" \
		-configuration Release \
		-archivePath $(ARCHIVE_PATH) \
		CODE_SIGN_STYLE=Automatic \
		-quiet | xcbeautify

export-ipa: archive ## Export IPA from archive
	@echo "📲 Exporting IPA..."
	@xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(EXPORT_PATH) \
		-exportOptionsPlist ExportOptions.plist \
		-quiet | xcbeautify

# Development Helpers
open: ## Open project in Xcode
	@echo "🚀 Opening Crookey.xcodeproj in Xcode..."
	@open Crookey.xcodeproj

simulator: ## Open iOS Simulator
	@echo "📱 Opening iOS Simulator..."
	@open -a Simulator

devices: ## List available simulators
	@echo "📱 Available simulators:"
	@xcrun simctl list devices available | grep -E "(iPhone|iPad)"

# Maintenance
update-tools: ## Update development tools
	@echo "🔄 Updating development tools..."
	@brew update
	@brew upgrade swiftlint swiftformat xcbeautify || true

# CI/CD
ci-lint: lint format-check ## Run CI linting checks
	@echo "✅ CI linting checks passed"

ci-test: test analyze ## Run CI testing and analysis
	@echo "✅ CI testing completed"

ci-build: build-release ## Run CI build
	@echo "✅ CI build completed"

# Quick Development Workflow
dev: lint build test ## Quick development workflow (lint, build, test)
	@echo "✅ Development workflow completed"

# Full CI Simulation
ci: clean ci-lint ci-build ci-test ## Simulate full CI pipeline
	@echo "✅ Full CI simulation completed"

# Utilities
install-deps: ## Install required dependencies
	@echo "📦 Installing dependencies..."
	@if ! command -v brew &> /dev/null; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	fi
	@brew install swiftlint swiftformat xcbeautify

bootstrap: install-deps setup ## Full project bootstrap
	@echo "🎉 Project bootstrap completed!"

.PHONY: help setup lint lint-fix format format-check build build-release clean test test-unit test-ui test-coverage analyze archive export-ipa open simulator devices update-tools ci-lint ci-test ci-build dev ci install-deps bootstrap