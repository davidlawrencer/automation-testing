//
//  Embrace_EcommerceUITests+BackgroundForeground.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest
import OSLog

// MARK: - Background/Foreground Extension

extension Embrace_EcommerceUITests {

    /// Sends the app to background to trigger Embrace session uploads
    /// Uses XCUIDevice.shared.press(.home) which is Embrace's proven test method
    func sendAppToBackground() {
        let logger = Logger(subsystem: "com.embrace.ecommerce.uitest", category: "lifecycle")

        print("📱 Pressing home button to background app...")
        logger.info("🔄 TEST_LIFECYCLE: Backgrounding app - expecting SDK to transition session state")

        // Press home button - This is the method Embrace SDK uses in their own tests
        // See: EmbraceIOTestSessionSpanUITests.swift and EmbraceIOTestPostedPayloads.swift
        XCUIDevice.shared.press(XCUIDevice.Button.home)

        // Wait for state transition and upload queue processing
        // Testing hypothesis: SDK needs more time in background for uploads
        // Increased from 3s to 15s to give SDK time to process and queue uploads
        sleep(15)

        print("✅ App backgrounded, session upload triggered")
        logger.info("✅ TEST_LIFECYCLE: App backgrounded - SDK should have saved session state")
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
        // Increased from 3s to 15s to give SDK time to process uploads
        sleep(15)

        print("✅ App foregrounded, background session upload triggered")
    }

    /// Terminates the app to force session end and upload
    func terminateApp() {
        let logger = Logger(subsystem: "com.embrace.ecommerce.uitest", category: "lifecycle")

        print("📱 Terminating app to force session end...")
        logger.info("🔄 TEST_LIFECYCLE: Terminating app - SDK should end session and save locally")

        app.terminate()

        // Wait for termination to complete and upload processing
        // Increased from 5s to 10s to give SDK more time to save session data
        sleep(10)

        print("✅ App terminated, session should be uploaded")
        logger.info("✅ TEST_LIFECYCLE: App terminated - session data should be persisted to disk")
    }
}
