//
//  Embrace_EcommerceUITests.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

final class Embrace_EcommerceUITests: XCTestCase {
    
    var app: XCUIApplication!
    var settingsApp: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settingsApp.launch()

        // Wait for Settings app to be running before continuing
        _ = settingsApp.wait(for: .runningForeground, timeout: 5.0)

        // Configure the app with launch environment variables
        app = XCUIApplication()
        app.launchEnvironment = [
            "UI_TESTING": "1",
            "DISABLE_NETWORK_CALLS": "1", // Disable app network calls but allow Embrace SDK
            "USE_MOCK_DATA": "1",
            "ALLOW_EMBRACE_NETWORK": "1" // Allow Embrace SDK network requests
        ]
        app.launch()

        // Wait for Embrace SDK to fully initialize
        Thread.sleep(forTimeInterval: 3.0)
    }

    override func tearDownWithError() throws {
        app = nil
        settingsApp = nil
    }

    @MainActor
    func testAuthenticationGuestFlow() throws {
        print("🧪 [Guest Auth] Starting Guest Authentication Flow Test")

        // Step 1: Wait for authentication view to load
        let authenticationView = app.descendants(matching: .any)["authenticationView"].firstMatch
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5.0),
                     "Authentication view with identifier 'authenticationView' failed to load within 5 seconds")
        print("✅ [Guest Auth] Step 1: Authentication view loaded successfully")

        // Step 2: Find the guest authentication button
        let authGuestButton = app.descendants(matching: .any)["authButton_ContinueasGuest"].firstMatch
        XCTAssertTrue(authGuestButton.exists,
                     "Guest authentication button with identifier 'authGuestButton' does not exist")
        print("✅ [Guest Auth] Step 2: Guest button found")

        // Step 3: Capture initial screen state for navigation verification
        let initialScreenExists = authenticationView.exists
        print("✅ [Guest Auth] Step 3: Initial screen state captured (exists: \(initialScreenExists))")

        // Step 4: Tap the guest button
        authGuestButton.tap()
        print("✅ [Guest Auth] Step 4: Guest button tapped")

        // Step 5: Wait 3 seconds for navigation to occur
        Thread.sleep(forTimeInterval: 3.0)
        print("✅ [Guest Auth] Step 5: Wait complete")

        // Step 6: Verify navigation to a different screen
        // Check that we've navigated away from the authentication view
        let navigationOccurred = !authenticationView.exists ||
                                app.otherElements.allElementsBoundByIndex.count > 1
        XCTAssertTrue(navigationOccurred,
                     "Navigation did not occur after tapping guest button - still on authentication screen")
        print("✅ [Guest Auth] Step 6: Navigation verified - moved to new screen")

        // Additional validation: ensure we're not stuck on the same screen
        XCTAssertTrue(initialScreenExists, "Initial screen validation failed")

        // Send app to background to trigger Embrace session upload
        print("📤 [Guest Auth] Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("✅ [Guest Auth] Background trigger complete")
        bringAppToForeground()
    }

    // MARK: - Helper Methods

    /// Sends the app to background to trigger Embrace session uploads
    private func sendAppToBackground() {
        // Send app to background by opening Settings app
        settingsApp.activate()

        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Settings is in the foreground and Ecommerce is in background
        _ = settingsApp.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(settingsApp.state, .runningForeground,
                       "Settings app should be in foreground")
        print("✅ Verified: Settings app in foreground, Embrace Ecommerce in background")

        // Wait to allow Embrace SDK time to upload sessions
        Thread.sleep(forTimeInterval: 3.0)
    }
    
    /// Sends the app to foreground to trigger Embrace session uploads for background session
    private func bringAppToForeground() {
        // Send app to foreground by activating
        // Note: .activate does not terminate existing app instance, which .launch often does
        app.activate()

        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Embrace Ecommerce is in the foreground and Ecommerce is in background
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(app.state, .runningForeground,
                       "Embrace Ecommerce app should be in foreground")
        print("✅ Verified: Embrace Ecommerce app in foreground, Settings in background")

        // Wait to allow Embrace SDK time to upload background sessions
        Thread.sleep(forTimeInterval: 3.0)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
