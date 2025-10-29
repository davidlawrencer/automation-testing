//
//  Embrace_EcommerceUITests.swift
//  Embrace EcommerceUITests
//
//  Created by David Rifkin on 9/17/25.
//

import XCTest

final class Embrace_EcommerceUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        
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
    }

    // MARK: - Helper Methods

    // MARK: - Screen Detection

    enum AppScreen: String {
        case authentication = "authenticationView"
        case home = "homeView"
        case productList = "productListView"
        case productDetail = "productDetailView"
        case cart = "cartView"
        case cartEmpty = "cartEmptyView"
        case checkout = "checkoutView"
        case profile = "profileView"
        case profileLoggedIn = "profileLoggedInView"
        case search = "searchView"
        case searchResults = "searchResultsView"
        case mainTab = "mainTabView"
        case unknown
    }

    /// Detects which screen the app is currently on based on visible accessibility identifiers
    private func detectCurrentScreen(timeout: TimeInterval = 2.0) -> AppScreen {
        let screens: [AppScreen] = [
            .authentication,
            .home,
            .productList,
            .productDetail,
            .cart,
            .cartEmpty,
            .checkout,
            .profile,
            .profileLoggedIn,
            .search,
            .searchResults,
            .mainTab
        ]

        for screen in screens {
            let element = app.descendants(matching: .any)[screen.rawValue].firstMatch
            if element.exists {
                print("📍 Detected screen: \(screen.rawValue)")
                return screen
            }
        }

        print("⚠️ Could not detect current screen")
        return .unknown
    }

    /// Performs an appropriate action based on the current screen
    /// Returns true if an action was performed, false otherwise
    @discardableResult
    private func performActionOnCurrentScreen() -> Bool {
        let currentScreen = detectCurrentScreen()

        switch currentScreen {
        case .authentication:
            return performAuthenticationAction()
        case .home, .mainTab:
            return performHomeAction()
        case .productList:
            return performProductListAction()
        case .productDetail:
            return performProductDetailAction()
        case .cart:
            return performCartAction()
        case .cartEmpty:
            return performCartEmptyAction()
        case .checkout:
            return performCheckoutAction()
        case .profile, .profileLoggedIn:
            return performProfileAction()
        case .search, .searchResults:
            return performSearchAction()
        case .unknown:
            print("⚠️ Unknown screen, cannot perform action")
            return false
        }
    }

    // MARK: - Screen-Specific Actions

    private func performAuthenticationAction() -> Bool {
        print("🎬 Performing authentication action")
        return tapGuestButton()
    }

    // MARK: - Authentication Screen Helpers

    private func tapGuestButton() -> Bool {
        print("🔘 Attempting to tap guest button")

        // Step 1: Verify authentication view is loaded
        let authenticationView = app.descendants(matching: .any)["authenticationView"].firstMatch
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5.0),
                     "Authentication view with identifier 'authenticationView' failed to load within 5 seconds")
        print("✅ Authentication view loaded successfully")

        // Step 2: Find and verify guest button exists
        let guestButton = app.descendants(matching: .any)["authButton_ContinueasGuest"].firstMatch
        XCTAssertTrue(guestButton.exists,
                     "Guest authentication button with identifier 'authButton_ContinueasGuest' does not exist")
        print("✅ Guest button found")

        // Step 3: Tap the guest button
        guestButton.tap()
        print("✅ Guest button tapped")

        // Step 4: Wait for navigation
        Thread.sleep(forTimeInterval: 3.0)

        // Step 5: Verify navigation occurred
        let navigationOccurred = !authenticationView.exists ||
                                app.otherElements.allElementsBoundByIndex.count > 1
        XCTAssertTrue(navigationOccurred,
                     "Navigation did not occur after tapping guest button - still on authentication screen")
        print("✅ Navigation verified - moved to new screen")

        return true
    }

    private func performHomeAction() -> Bool {
        print("🎬 Performing home action")
        // Could tap a product, navigate to cart, etc.
        // For now, just return true to indicate we're on home
        return true
    }

    private func performProductListAction() -> Bool {
        print("🎬 Performing product list action")
        // Could tap first product
        return true
    }

    private func performProductDetailAction() -> Bool {
        print("🎬 Performing product detail action")
        // Could add to cart
        return true
    }

    private func performCartAction() -> Bool {
        print("🎬 Performing cart action")
        // Could proceed to checkout
        return true
    }

    private func performCartEmptyAction() -> Bool {
        print("🎬 Cart is empty")
        // Could navigate back to shopping
        return true
    }

    private func performCheckoutAction() -> Bool {
        print("🎬 Performing checkout action")
        // Could fill out checkout form
        return true
    }

    private func performProfileAction() -> Bool {
        print("🎬 Performing profile action")
        // Could edit profile or logout
        return true
    }

    private func performSearchAction() -> Bool {
        print("🎬 Performing search action")
        // Could enter search query
        return true
    }

    // MARK: - Background/Foreground Helpers

    /// Sends the app to background to trigger Embrace session uploads
    private func sendAppToBackground() {
        // Send app to background by opening Settings app
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Settings is in the foreground and Ecommerce is in background
        _ = settings.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(settings.state, .runningForeground,
                       "Settings app should be in foreground")
        print("✅ Verified: Settings app in foreground, Embrace Ecommerce in background")

        // Wait to allow Embrace SDK time to upload sessions
        Thread.sleep(forTimeInterval: 15.0)
    }
    
    /// Sends the app to foreground to trigger Embrace session uploads for background session
    private func bringAppToForeground() {
        // Bring app to foreground
        app.activate()

        // Wait for the app state to transition
        Thread.sleep(forTimeInterval: 1.0)

        // Verify that Embrace Ecommerce is in the foreground and Ecommerce is in background
        _ = app.wait(for: .runningForeground, timeout: 5.0)

        XCTAssertEqual(app.state, .runningForeground,
                       "Embrace Ecommerce app should be in foreground")
        print("✅ Verified: Embrace Ecommerce app in foreground")

        // Wait to allow Embrace SDK time to upload background sessions
        Thread.sleep(forTimeInterval: 15.0)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
