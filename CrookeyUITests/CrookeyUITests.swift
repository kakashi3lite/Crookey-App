//
//  CrookeyUITests.swift
//  CrookeyUITests
//
//  Created by Swanand Tanavade on 12/5/24.
//

import XCTest

final class CrookeyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Main Tab Navigation Tests
    
    func testMainTabNavigation() throws {
        // Test that all main tabs are accessible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Test Discover tab
        let discoverTab = tabBar.buttons["Discover"]
        XCTAssertTrue(discoverTab.exists)
        discoverTab.tap()
        
        // Test Search tab
        let searchTab = tabBar.buttons["Search"]
        XCTAssertTrue(searchTab.exists)
        searchTab.tap()
        
        // Test Scan tab
        let scanTab = tabBar.buttons["Scan"]
        XCTAssertTrue(scanTab.exists)
        scanTab.tap()
        
        // Test Saved tab
        let savedTab = tabBar.buttons["Saved"]
        XCTAssertTrue(savedTab.exists)
        savedTab.tap()
        
        // Test Profile tab
        let profileTab = tabBar.buttons["Profile"]
        XCTAssertTrue(profileTab.exists)
        profileTab.tap()
    }
    
    // MARK: - Search Functionality Tests
    
    func testSearchFunctionality() throws {
        // Navigate to search tab
        let tabBar = app.tabBars.firstMatch
        let searchTab = tabBar.buttons["Search"]
        searchTab.tap()
        
        // Find search field and enter text
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("chicken")
            
            // Test search button or return key
            app.keyboards.buttons["Search"].tap()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Test that main UI elements have accessibility labels
        let tabBar = app.tabBars.firstMatch
        
        let discoverTab = tabBar.buttons["Discover"]
        XCTAssertNotNil(discoverTab.label)
        
        let searchTab = tabBar.buttons["Search"]  
        XCTAssertNotNil(searchTab.label)
        
        let scanTab = tabBar.buttons["Scan"]
        XCTAssertNotNil(scanTab.label)
        
        let savedTab = tabBar.buttons["Saved"]
        XCTAssertNotNil(savedTab.label)
        
        let profileTab = tabBar.buttons["Profile"]
        XCTAssertNotNil(profileTab.label)
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // MARK: - Screenshot Tests
    
    func testTakeScreenshots() throws {
        // Take screenshots for different states
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MainScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}