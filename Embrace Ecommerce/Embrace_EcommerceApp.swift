//
//  Embrace_EcommerceApp.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/6/25.
//

import SwiftUI
import EmbraceIO
import GoogleSignIn
import Stripe
import Firebase
import Mixpanel
import OSLog

@main
struct Embrace_EcommerceApp: App {
    init() {
        print("🚀 Starting app initialization...")

        // TODO: receive launch arguments from UITest
        let environment = ProcessInfo.processInfo.environment

        if environment["UI_TESTING"] == "1" {
            print("📱 Running in UI Testing mode")
        }

        if environment["DISABLE_NETWORK_CALLS"] == "1" {
            print("🚫 Network calls disabled for testing")
        }

        if environment["USE_MOCK_DATA"] == "1" {
            print("🎭 Using mock data for testing")
        }

        do {
            // Initialize Firebase first (required for Firebase services)
            // Temporarily disabled to debug crash
            // configureFirebase()
            print("⚠️ Firebase configuration temporarily disabled for debugging")
            
            // Initialize Embrace SDK with comprehensive options
            configureEmbrace()
            print("✅ Embrace configuration completed")
            
            // Initialize Mixpanel
            configureMixpanel()
            print("✅ Mixpanel configuration completed")
            
            // Configure Google Sign-In
            // Temporarily commented out to debug crash
            // configureGoogleSignIn()
            print("⚠️ Google Sign-In configuration temporarily disabled for debugging")
            
            // Initialize Stripe
            configureStripe()
            print("✅ Stripe configuration completed")
            
            // Print configuration status and validate setup
            SDKConfiguration.printConfigurationStatus()
            
            // Log successful initialization
            EmbraceService.shared.logInfo("App initialization completed", properties: [
                "embrace_version": "6.14.1",
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "configuration_warnings": SDKConfiguration.validateConfiguration().joined(separator: ", ")
            ])
            
            print("🎉 App initialization completed successfully!")
            
            // Run SDK compatibility tests in debug mode
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                SDKCompatibilityTest.shared.runCompatibilityTests()
            }
            #endif
            
        } catch {
            print("❌ Critical error during app initialization: \(error)")
            // Don't crash the app, but log the error
        }
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured to prevent duplicate configuration
        if FirebaseApp.app() != nil {
            print("ℹ️ Firebase already configured, skipping configuration")
            return
        }
        
        // Check if GoogleService-Info.plist exists before configuring Firebase
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            do {
                FirebaseApp.configure()
                print("✅ Firebase configured successfully")
                EmbraceService.shared.addSessionProperty(key: "firebase_configured", value: "true")
            } catch {
                print("❌ Error configuring Firebase: \(error)")
                EmbraceService.shared.addSessionProperty(key: "firebase_configured", value: "false")
                EmbraceService.shared.addSessionProperty(key: "firebase_error", value: error.localizedDescription)
            }
        } else {
            print("⚠️ GoogleService-Info.plist not found. Firebase disabled for this session.")
            print("   To enable Firebase, add GoogleService-Info.plist from your Firebase project.")
            EmbraceService.shared.addSessionProperty(key: "firebase_configured", value: "false")
            EmbraceService.shared.addSessionProperty(key: "firebase_disabled_reason", value: "missing_config_file")
        }
    }
    
    private func configureEmbrace() {
        let logger = Logger(subsystem: "com.embrace.ecommerce", category: "sdk-init")

        do {
            // Explicitly log configuration for CI debugging using OSLog (captured by log stream)
            logger.info("🔧 EMBRACE_INIT: Configuring SDK with App ID: \(SDKConfiguration.Embrace.appId, privacy: .public)")
            logger.info("🔧 EMBRACE_INIT: Platform: iOS Simulator")

            // Create basic Embrace configuration
            // Using default log level (removing .trace to match working outdoors project)
            let options = Embrace.Options(
                appId: SDKConfiguration.Embrace.appId,
                platform: .default,
                export: nil
            )

            try Embrace
                .setup(options: options)
                .start()

            logger.info("✅ EMBRACE_INIT: SDK initialized successfully")
            logger.info("✅ EMBRACE_INIT: SDK started and ready to capture sessions")
            
            // Set initial session properties from configuration
            for (key, value) in SDKConfiguration.Embrace.sessionProperties {
                EmbraceService.shared.addSessionProperty(key: key, value: value)
            }
            EmbraceService.shared.addSessionProperty(key: "third_party_sdks", value: "firebase,mixpanel,stripe,google_signin", permanent: true)

            // Log environment for debugging CI vs local differences
            logger.info("🔍 EMBRACE_INIT: Environment check - XCTestConfigurationFilePath exists: \(ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)")
            logger.info("🔍 EMBRACE_INIT: Environment check - IS_XCTEST: \(ProcessInfo.processInfo.environment["IS_XCTEST"] ?? "not set", privacy: .public)")

            // TODO: Break into own function
            var runSource = "Simulator"
            if let sessionRunSource = ProcessInfo.processInfo.environment["RUN_SOURCE"] {
                runSource = sessionRunSource
            }

            logger.info("🔍 EMBRACE_INIT: Session property - session_run_source: \(runSource, privacy: .public)")
            EmbraceService.shared.addSessionProperty(key: "session_run_source", value: runSource)

        } catch let error {
            logger.error("❌ EMBRACE_INIT: CRITICAL ERROR starting Embrace SDK")
            logger.error("❌ EMBRACE_INIT: Error: \(error.localizedDescription, privacy: .public)")
            if let nsError = error as NSError? {
                logger.error("❌ EMBRACE_INIT: Domain: \(nsError.domain, privacy: .public)")
                logger.error("❌ EMBRACE_INIT: Code: \(nsError.code)")
                logger.error("❌ EMBRACE_INIT: UserInfo: \(String(describing: nsError.userInfo), privacy: .public)")
            }
            // Still continue app initialization even if Embrace fails
        }
    }
    
    private func configureMixpanel() {
        // Initialize Mixpanel with project token from configuration
        if SDKConfiguration.Mixpanel.isConfigured {
            Mixpanel.initialize(
                token: SDKConfiguration.Mixpanel.projectToken,
                trackAutomaticEvents: SDKConfiguration.Mixpanel.trackAutomaticEvents
            )
            print("✅ Mixpanel configured successfully")
        } else {
            print("⚠️ Mixpanel using placeholder token - replace with actual project token")
            // Initialize with a mock token for development
            Mixpanel.initialize(token: "mock_token_for_testing", trackAutomaticEvents: false)
        }
        
        // Test Mixpanel and Embrace compatibility
        EmbraceService.shared.addSessionProperty(key: "mixpanel_configured", value: "true")
        EmbraceService.shared.logInfo("Mixpanel SDK initialized alongside Embrace")
    }
    
    private func configureGoogleSignIn() {
        do {
            // First, try to get client ID from Info.plist (recommended approach)
            if let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
                print("✅ Found GIDClientID in Info.plist: \(clientId)")
                let config = GIDConfiguration(clientID: clientId)
                GIDSignIn.sharedInstance.configuration = config
                print("✅ Google Sign-In configured successfully")
                return
            }
            
            // Fallback: try to read from GoogleService-Info.plist
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let plist = NSDictionary(contentsOfFile: path),
               let clientId = plist["CLIENT_ID"] as? String {
                print("✅ Found CLIENT_ID in GoogleService-Info.plist: \(clientId)")
                let config = GIDConfiguration(clientID: clientId)
                GIDSignIn.sharedInstance.configuration = config
                print("✅ Google Sign-In configured successfully from plist")
                return
            }
            
            // Last resort: use fallback
            print("⚠️ No Google configuration found. Using fallback.")
            let testClientId = SDKConfiguration.GoogleSignIn.fallbackClientId
            let config = GIDConfiguration(clientID: testClientId)
            GIDSignIn.sharedInstance.configuration = config
            
        } catch {
            print("❌ Error configuring Google Sign-In: \(error)")
        }
    }
    
    private func configureStripe() {
        // Stripe is initialized automatically when StripePaymentService is first accessed
        // The publishable key is set in StripePaymentService.init()
        print("✅ Stripe configured for test environment")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CartManager())
                .environmentObject(MockDataService.shared)
                .environmentObject(AuthenticationManager())
                .onOpenURL { url in
                    // Handle Google Sign-In URL
                    GIDSignIn.sharedInstance.handle(url)
                    
                    // Track deep link / URL scheme handling
                    EmbraceService.shared.addBreadcrumb(message: "App opened via URL: \(url.absoluteString)")
                    
                    if url.scheme == "googlesignin" || url.absoluteString.contains("oauth") {
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "google_signin_redirect")
                        EmbraceService.shared.logInfo("Google Sign-In URL handled", properties: ["url": url.absoluteString])
                        
                    } else if url.scheme == "embrace-ecommerce" && url.host == "stripe-redirect" {
                        // Handle Stripe redirect URL
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "stripe_redirect")
                        EmbraceService.shared.logInfo("Stripe redirect URL handled", properties: ["url": url.absoluteString])
                        print("✅ Stripe redirect URL handled: \(url)")
                        
                    } else {
                        // Handle other deep links
                        EmbraceService.shared.addSessionProperty(key: "launch_source", value: "deeplink")
                        EmbraceService.shared.logInfo("Deep link handled", properties: [
                            "scheme": url.scheme ?? "unknown",
                            "host": url.host ?? "unknown",
                            "url": url.absoluteString
                        ])
                    }
                }
                .onAppear {
                    // Restore previous Google Sign-In state on app launch
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user = user {
                            print("✅ Google Sign-In: Previous sign-in restored for \(user.profile?.email ?? "unknown")")
                        } else if let error = error {
                            print("ℹ️ Google Sign-In: No previous sign-in to restore - \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}
