# Privacy Verification Checklist

## Crookey Privacy-First Architecture - QA Playbook

**Version:** 1.0.0
**Last Updated:** 2025-11-17
**Applies To:** MVP Release

---

## 🔒 Executive Summary

This document provides a comprehensive QA checklist to verify that Crookey maintains its core privacy-first architecture. **All items must pass** before any production release.

### Core Privacy Guarantees

1. ✅ **Zero-Liability Architecture**: No user pantry data stored on company servers
2. ✅ **On-Device AI**: All recipe generation happens locally using Foundation Models
3. ✅ **Encrypted at Rest**: SQLite database protected via iOS Data Protection
4. ✅ **No Data Harvesting**: Zero analytics, zero tracking, zero third-party data selling
5. ✅ **Consent-First Exports**: One-way data push (no credential storage)

---

## 1. Database Privacy Verification

### 1.1 Local Storage Only

**Requirement:** All user data must be stored in local SQLite database, never transmitted without consent.

#### Verification Steps

- [ ] **File Location Check**
  ```bash
  # Database must be in app's sandboxed Documents directory
  # Path: ~/Library/Application Support/.../Documents/CrookeyPantry.sqlite
  ```
  - [ ] Verify database file exists in Documents directory
  - [ ] Confirm file is NOT in shared container
  - [ ] Confirm no cloud sync enabled by default

- [ ] **File Protection Check**
  ```swift
  // Core/Storage/DatabaseService.swift:92-101
  // Verify FileProtectionType.complete is enabled
  let attributes = try FileManager.default.attributesOfItem(atPath: dbPath)
  assert(attributes[.protectionKey] == FileProtectionType.complete)
  ```
  - [ ] Database file has `.protectionKey` set to `.complete`
  - [ ] File is encrypted when device is locked
  - [ ] File is inaccessible without device passcode

- [ ] **Schema Privacy Audit**
  - [ ] `UserPantry` table contains only local inventory data
  - [ ] No user identifiable information (email, phone, name) stored
  - [ ] No third-party identifiers (advertising ID, session tokens)
  - [ ] No geolocation data stored

### 1.2 Initialization Security

**Requirement:** Database initialization must fail gracefully without compromising security.

#### Verification Steps

- [ ] **Error Handling**
  ```swift
  // Core/Storage/DatabaseService.swift:44-61
  // Verify initializationError is captured
  ```
  - [ ] Test database initialization failure scenarios
  - [ ] Verify `initializationError` is populated on failure
  - [ ] Confirm app doesn't crash, shows user-friendly error
  - [ ] Verify no sensitive data in error messages

- [ ] **Integrity Checks**
  ```swift
  // Core/Storage/DatabaseService.swift:147-167
  // PRAGMA integrity_check must run on init
  ```
  - [ ] Database integrity verified on each initialization
  - [ ] Corrupted databases are detected and reported
  - [ ] User is prompted to reset if corruption detected

---

## 2. AI Recipe Generation Privacy

### 2.1 On-Device Processing

**Requirement:** All AI inference must execute locally using Apple Foundation Models. Zero API calls to external LLM services.

#### Verification Steps

- [ ] **Network Monitoring Test**
  ```bash
  # Run recipe generation with network disconnected
  # Recipe should still generate successfully
  ```
  - [ ] Generate recipe in Airplane Mode
  - [ ] Verify recipe is created successfully
  - [ ] Confirm zero network requests in Xcode Network Inspector
  - [ ] Test with multiple ingredient combinations

- [ ] **Foundation Models Integration**
  ```swift
  // Services/RecipeService.swift:47-92
  // Verify LMSession is used (not external API)
  ```
  - [ ] Confirm `FoundationModels` framework is imported
  - [ ] Verify `LMSession()` is used for generation
  - [ ] Check no URLSession or HTTP clients in RecipeService
  - [ ] Validate availability check for iOS 18.2+

- [ ] **Prompt Construction Audit**
  ```swift
  // Services/RecipeService.swift:112-152
  // Prompt must not include PII
  ```
  - [ ] Review prompt builder in `buildRecipePrompt()`
  - [ ] Confirm only ingredient names are included (no user data)
  - [ ] Verify no device identifiers in prompt
  - [ ] Check no location data in context

### 2.2 Privacy Messaging

**Requirement:** User must be explicitly informed that recipe generation is on-device.

#### Verification Steps

- [ ] **Privacy Message Display**
  ```swift
  // Core/Storage/PantryModels.swift:98-100
  // GeneratedRecipe.privacyMessage property
  ```
  - [ ] Verify privacy message is displayed in UI
  - [ ] Message states: "100% on your device"
  - [ ] Message confirms "data never left your phone"
  - [ ] Message is visible on every generated recipe

---

## 3. Service Layer Privacy Audit

### 3.1 PantryService

**Requirement:** PantryService must never initiate network calls or expose data.

#### Verification Steps

- [ ] **Code Audit**
  ```swift
  // Services/PantryService.swift
  // Search for: URLSession, URLRequest, Alamofire, HTTP
  ```
  - [ ] Grep for network-related imports: `grep -r "import Alamofire" Services/`
  - [ ] Verify no URLSession instances
  - [ ] Confirm no HTTP clients
  - [ ] Check no analytics SDKs (Firebase, Mixpanel, etc.)

- [ ] **Test Coverage**
  ```swift
  // CrookeyTests/PantryServicesTests.swift:448-462
  // testNoNetworkCallsDuringPantryOperations
  ```
  - [ ] Run privacy test: `testNoNetworkCallsDuringPantryOperations()`
  - [ ] Verify test passes without network access
  - [ ] Confirm all CRUD operations work offline

### 3.2 RecipeService

**Requirement:** RecipeService must not communicate with external AI APIs.

#### Verification Steps

- [ ] **API Key Audit**
  ```bash
  # Search for API keys or secrets
  grep -r "API_KEY\|OPENAI\|ANTHROPIC\|GEMINI" .
  ```
  - [ ] No OpenAI API keys in codebase
  - [ ] No Anthropic API keys
  - [ ] No Google Gemini keys
  - [ ] No `.env` files with cloud AI credentials

- [ ] **Fallback Behavior**
  ```swift
  // Services/RecipeService.swift:65-89
  // Mock recipe fallback must not call network
  ```
  - [ ] Test on iOS < 18.2 (no Foundation Models)
  - [ ] Verify fallback returns mock recipe locally
  - [ ] Confirm no graceful degradation to cloud API

---

## 4. Data Minimization Verification

### 4.1 No Tracking

**Requirement:** Zero analytics, telemetry, or user behavior tracking.

#### Verification Steps

- [ ] **Analytics SDK Audit**
  ```bash
  # Check Podfile, Package.swift, or SPM dependencies
  grep -i "firebase\|mixpanel\|amplitude\|segment" Podfile Package.swift
  ```
  - [ ] No Firebase Analytics
  - [ ] No Google Analytics
  - [ ] No Mixpanel, Amplitude, or similar
  - [ ] No crash reporting that sends stack traces (unless opt-in)

- [ ] **OSLog Usage**
  ```swift
  // All services use OSLog (stays on device by default)
  import OSLog
  let logger = Logger(subsystem: "com.crookey.app", category: "ServiceName")
  ```
  - [ ] Verify logging uses `OSLog` framework
  - [ ] Confirm no custom logging that uploads to server
  - [ ] Check logs don't contain user data (ingredient names ok, but not personal info)

### 4.2 No Third-Party Data Sharing

**Requirement:** No user data sold, shared, or transmitted to third parties.

#### Verification Steps

- [ ] **Privacy Manifest** (App Privacy Report)
  ```xml
  <!-- PrivacyInfo.xcprivacy -->
  <!-- Must declare: "Data Not Collected" -->
  ```
  - [ ] Create/verify `PrivacyInfo.xcprivacy` file
  - [ ] Declare "Data Not Collected" for all categories
  - [ ] No data types marked as "Collected"
  - [ ] Submit for App Store review

- [ ] **Network Requests Audit**
  ```bash
  # Search for all network domains
  grep -r "https://" . --include="*.swift" | grep -v "comment"
  ```
  - [ ] List all external domains accessed
  - [ ] Verify domains are only for:
    - [ ] App Store API (subscriptions)
    - [ ] CloudKit (E2EE sync, opt-in only)
    - [ ] Instacart API (one-way export, consent-gated)
  - [ ] No ad networks, analytics domains, or tracking pixels

---

## 5. Consent & Export Privacy

### 5.1 Shopping List Export (Future)

**Requirement:** User must explicitly consent before any data leaves device.

#### Verification Steps (When Implemented)

- [ ] **Consent UI**
  - [ ] User sees explicit consent sheet before first export
  - [ ] Consent message states what data is sent (shopping list only)
  - [ ] Consent is revocable in Settings
  - [ ] Export fails gracefully if consent is denied

- [ ] **One-Way Data Flow**
  - [ ] App never stores Instacart credentials
  - [ ] App never stores OAuth tokens long-term
  - [ ] API call is stateless (no session tracking)
  - [ ] User re-authenticates with Instacart directly (OAuth)

### 5.2 CloudKit Sync (Optional Feature)

**Requirement:** If CloudKit sync is enabled, it must use E2EE with Advanced Data Protection.

#### Verification Steps (When Implemented)

- [ ] **E2EE Verification**
  ```swift
  // Use CloudKit private database with CKRecord
  // User must enable Advanced Data Protection on iCloud
  ```
  - [ ] Sync uses CloudKit Private Database (not Public)
  - [ ] Data is stored in user's iCloud (not company's)
  - [ ] Verify E2EE is enabled: Settings > Apple ID > iCloud > Advanced Data Protection
  - [ ] Company cannot decrypt user's pantry data

- [ ] **Opt-In Only**
  - [ ] Sync is disabled by default
  - [ ] User must explicitly enable in Settings
  - [ ] Clear UI explaining E2EE requirement
  - [ ] App works 100% offline if sync disabled

---

## 6. Security Testing

### 6.1 Static Analysis

#### Verification Steps

- [ ] **SwiftLint Security Rules**
  ```bash
  swiftlint lint --strict
  ```
  - [ ] Run SwiftLint with security-focused rules
  - [ ] Fix all "Force Unwrapping" warnings (crash safety)
  - [ ] Fix all "Force Try" warnings (error handling)

- [ ] **Xcode Static Analyzer**
  ```bash
  xcodebuild analyze -scheme Crookey -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```
  - [ ] Run Xcode Analyze (Product > Analyze)
  - [ ] Resolve all memory leak warnings
  - [ ] Fix all potential null pointer dereferences

### 6.2 Dynamic Testing

#### Verification Steps

- [ ] **Unit Tests**
  ```bash
  xcodebuild test -scheme Crookey -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```
  - [ ] All tests in `PantryServicesTests.swift` pass
  - [ ] Privacy test `testNoNetworkCallsDuringPantryOperations()` passes
  - [ ] File protection test `testDatabaseFileProtection()` passes
  - [ ] Code coverage > 80% for critical paths

- [ ] **Manual QA**
  - [ ] Add 10+ items to pantry in Airplane Mode
  - [ ] Generate 5 recipes in Airplane Mode
  - [ ] Force quit app, verify data persists
  - [ ] Delete app, reinstall, verify data is wiped (no cloud backup)

---

## 7. Pre-Release Checklist

### Before Submitting to TestFlight

- [ ] All sections above are ✅ verified
- [ ] Privacy Nutrition Label completed in App Store Connect
- [ ] Data types: **"Data Not Collected"** for all categories
- [ ] Create screen recording showing:
  - [ ] Recipe generation in Airplane Mode
  - [ ] Pantry CRUD in Airplane Mode
  - [ ] Privacy message displayed on generated recipe
- [ ] Add to release notes: "100% Private: All AI processing on-device. Zero data collection."

### Before Public Release (App Store)

- [ ] Complete Privacy Audit (this checklist)
- [ ] Legal review of privacy policy (if any)
- [ ] Verify App Store privacy questions answered correctly
- [ ] Test on physical device (not just simulator)
- [ ] External security audit (optional but recommended)

---

## 8. Ongoing Monitoring

### Post-Launch Privacy Maintenance

- [ ] **Quarterly Audits**
  - [ ] Re-run this checklist every 3 months
  - [ ] Verify no new third-party SDKs added
  - [ ] Check for framework updates that change privacy

- [ ] **Dependency Audits**
  ```bash
  # Check for new dependencies
  swift package show-dependencies
  ```
  - [ ] Review all new Swift Package Manager dependencies
  - [ ] Verify no analytics or tracking libraries
  - [ ] Confirm dependencies respect privacy-first mandate

- [ ] **User Reports**
  - [ ] Monitor GitHub issues for privacy concerns
  - [ ] Respond to all privacy-related inquiries within 24 hours
  - [ ] Maintain transparency log of any data handling changes

---

## Appendix: Red Flags (Auto-Fail)

**If any of these are detected, the release must be blocked:**

❌ **API keys for OpenAI, Anthropic, Google Gemini, or similar cloud AI services**
❌ **Firebase Analytics, Google Analytics, Mixpanel, or similar tracking SDKs**
❌ **User credentials for third-party services stored locally or on server**
❌ **Network requests during recipe generation (excluding app initialization)**
❌ **Database file without FileProtectionType.complete encryption**
❌ **Personally Identifiable Information (PII) in logs or error messages**
❌ **App Privacy Nutrition Label lists any "Data Collected"**

---

## Contacts

**Privacy Officer:** [Swanand Tanavade](mailto:swanandtanavade@gmail.com)
**GitHub Issues:** [https://github.com/kakashi3lite/Crookey/issues](https://github.com/kakashi3lite/Crookey/issues)

---

**Document Control**
**Version History:**
- v1.0.0 (2025-11-17): Initial privacy verification framework for MVP

**Next Review Date:** 2025-12-17
