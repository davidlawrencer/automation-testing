//
//  Embrace_EcommerceUITests.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest
import OSLog

final class Embrace_EcommerceUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Configure the app with launch environment variables
        app = XCUIApplication()
        app.launchEnvironment = [
            "UI_TESTING": "1", // NOT IN USE.
            "DISABLE_NETWORK_CALLS": "1", // NOT IN USE. Disable app network calls but allow Embrace SDK
            "USE_MOCK_DATA": "1", // NOT IN USE.
            "ALLOW_EMBRACE_NETWORK": "1", // NOT IN USE. Allow Embrace SDK network requests
            "RUN_SOURCE": "UITest" // Sends information about how session was run
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testFlow() throws {
        print("🧪 Starting adaptive test flow")

        // Detect current screen and perform appropriate action
        let currentScreen = detectCurrentScreen()
        print("📍 Current screen: \(currentScreen)")

        // Perform action based on detected screen
        let actionPerformed = performActionOnCurrentScreen()
        XCTAssertTrue(actionPerformed, "Failed to perform action on screen: \(currentScreen)")

        // Send app to background to trigger Embrace session upload
        print("📤 Sending app to background to trigger Embrace session upload...")
        sendAppToBackground()
        print("✅ Background trigger complete")

        // Bring app back to foreground to trigger upload of backgrounded session
        print("📤 Bringing app to foreground to trigger session upload...")
        bringAppToForeground()
        print("✅ Foreground trigger complete")

        // Background/foreground one more time to ensure uploads complete
        print("📤 Final background/foreground cycle to ensure all uploads...")
        sendAppToBackground()
        bringAppToForeground()
        print("✅ Final cycle complete")

        // Terminate app to end session (session data saved locally)
        print("📤 Terminating app to end session...")
        terminateApp()
        print("✅ App terminated, session data saved locally")

        // CRITICAL: Relaunch app to trigger upload of previous session
        // Embrace SDK uploads sessions on the NEXT app launch, not during termination
        let logger = Logger(subsystem: "com.embrace.ecommerce.uitest", category: "lifecycle")

        print("🚀 Relaunching app to trigger upload of previous session...")
        logger.info("🔄 TEST_LIFECYCLE: Relaunching app - SDK should detect previous session and upload it")
        app.launch()
        print("✅ App relaunched, previous session should now be uploading")
        logger.info("✅ TEST_LIFECYCLE: App relaunched - upload should be in progress")

        // Wait for upload to complete
        print("⏳ Waiting for session upload to complete...")
        logger.info("⏳ TEST_LIFECYCLE: Waiting 30s for upload to complete")
        sleep(30)
        print("✅ Upload wait complete")
        logger.info("✅ TEST_LIFECYCLE: Wait complete - session should be uploaded by now")

        // Terminate again to end the relaunch session
        print("📤 Final app termination...")
        logger.info("🔄 TEST_LIFECYCLE: Final termination")
        app.terminate()
        print("✅ Test complete")
        logger.info("✅ TEST_LIFECYCLE: Test complete")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
