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
    /// Uses XCUIDevice.shared.press(.home) which is Embrace's proven test method
    func sendAppToBackground() {
        print("📱 Pressing home button to background app...")

        // Press home button - This is the method Embrace SDK uses in their own tests
        // See: EmbraceIOTestSessionSpanUITests.swift and EmbraceIOTestPostedPayloads.swift
        XCUIDevice.shared.press(XCUIDevice.Button.home)

        // Wait for state transition and upload queue processing
        // Embrace's tests use 1-2 seconds, using 3 for CI reliability
        sleep(3)

        print("✅ App backgrounded, session upload triggered")
    }

    /// Brings the app to foreground to trigger Embrace session uploads for background session
    func bringAppToForeground() {
        print("📱 Activating app to foreground...")

        // Bring app to foreground
        app.activate()

        // Verify app is running in foreground
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(app.state, .runningForeground,
                       "Embrace Ecommerce app should be in foreground")

        // Wait for state transition and upload queue processing
        sleep(3)

        print("✅ App foregrounded, background session upload triggered")
    }
}
