//
//  Embrace_EcommerceUITests+BackgroundForeground.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

// MARK: - Background/Foreground Extension

extension Embrace_EcommerceUITests {

    /// Sends the app to background to trigger Embrace session uploads
    func sendAppToBackground() {
        // Send app to background by opening Settings app
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()

        // Verify that Settings is in the foreground and Ecommerce is in background
        _ = settings.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(settings.state, .runningForeground,
                       "Settings app should be in foreground")
        print("✅ Verified: Settings app in foreground, Embrace Ecommerce in background")
    }

    /// Sends the app to foreground to trigger Embrace session uploads for background session
    func bringAppToForeground() {
        // Bring app to foreground
        app.activate()

        // Verify that Embrace Ecommerce is in the foreground and Ecommerce is in background
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(app.state, .runningForeground,
                       "Embrace Ecommerce app should be in foreground")
        print("✅ Verified: Embrace Ecommerce app in foreground")
    }
}
