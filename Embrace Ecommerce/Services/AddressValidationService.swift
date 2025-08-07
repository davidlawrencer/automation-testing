import Foundation

enum AddressValidationError: LocalizedError {
    case invalidStreetAddress
    case invalidCity
    case invalidState
    case invalidZipCode
    case unserviceableArea
    case networkTimeout
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidStreetAddress:
            return "Please enter a valid street address"
        case .invalidCity:
            return "Please enter a valid city name"
        case .invalidState:
            return "Please enter a valid state"
        case .invalidZipCode:
            return "Please enter a valid ZIP code"
        case .unserviceableArea:
            return "We don't deliver to this area"
        case .networkTimeout:
            return "Address validation timed out. Please try again"
        case .serviceUnavailable:
            return "Address validation service is temporarily unavailable"
        }
    }
}

struct AddressValidationResult {
    let isValid: Bool
    let suggestedAddress: Address?
    let confidence: Double
    let errors: [AddressValidationError]
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasSuggestion: Bool {
        return suggestedAddress != nil
    }
}

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let formattedAddress: String
    let street: String
    let street2: String?
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let confidence: Double
}

@MainActor
class AddressValidationService: ObservableObject {
    private let mockNetworkService: MockNetworkService
    
    @Published var isValidating = false
    @Published var validationResults: [String: AddressValidationResult] = [:]
    
    init(mockNetworkService: MockNetworkService = .shared) {
        self.mockNetworkService = mockNetworkService
    }
    
    func validateAddress(_ address: Address, simulateError: Bool = false) async throws -> AddressValidationResult {
        isValidating = true
        defer { isValidating = false }
        
        let span = EmbraceManager.shared.startSpan(name: "address_validation", type: .performance)
        span?.setAttribute(key: "address.city", value: address.city)
        span?.setAttribute(key: "address.state", value: address.state)
        span?.setAttribute(key: "address.zip_code", value: address.zipCode)
        
        do {
            let result = try await performValidation(address, simulateError: simulateError)
            validationResults[address.id] = result
            
            span?.setAttribute(key: "validation.is_valid", value: result.isValid)
            span?.setAttribute(key: "validation.confidence", value: result.confidence)
            span?.setAttribute(key: "validation.has_suggestion", value: result.hasSuggestion)
            
            if result.hasErrors {
                EmbraceManager.shared.logMessage(
                    "Address validation errors: \(result.errors.map { $0.localizedDescription })",
                    severity: .warning,
                    properties: [
                        "address_id": address.id,
                        "error_count": result.errors.count,
                        "city": address.city,
                        "state": address.state
                    ]
                )
            }
            
            span?.setStatus(.ok)
            span?.end()
            return result
            
        } catch {
            span?.setAttribute(key: "error.type", value: String(describing: type(of: error)))
            span?.setAttribute(key: "error.message", value: error.localizedDescription)
            span?.setStatus(.error, description: error.localizedDescription)
            span?.end()
            
            EmbraceManager.shared.logMessage(
                "Address validation failed",
                severity: .error,
                properties: [
                    "address_id": address.id,
                    "error": error.localizedDescription
                ]
            )
            
            throw error
        }
    }
    
    func searchAddressSuggestions(query: String) async throws -> [AddressSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let span = EmbraceManager.shared.startSpan(name: "address_suggestions_search", type: .performance)
        span?.setAttribute(key: "search.query", value: query)
        span?.setAttribute(key: "search.query_length", value: query.count)
        
        try await Task.sleep(nanoseconds: UInt64.random(in: 200_000_000...800_000_000))
        
        let suggestions = generateMockSuggestions(for: query)
        span?.setAttribute(key: "search.results_count", value: suggestions.count)
        span?.setStatus(.ok)
        span?.end()
        
        EmbraceManager.shared.logMessage(
            "Address suggestions retrieved",
            severity: .info,
            properties: [
                "query": query,
                "results_count": suggestions.count
            ]
        )
        
        return suggestions
    }
    
    private func performValidation(_ address: Address, simulateError: Bool) async throws -> AddressValidationResult {
        try await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        
        if simulateError {
            let randomError = [
                AddressValidationError.networkTimeout,
                AddressValidationError.serviceUnavailable,
                AddressValidationError.unserviceableArea
            ].randomElement()!
            throw randomError
        }
        
        let scenario = ValidationScenario.allCases.randomElement()!
        
        switch scenario {
        case .valid:
            return AddressValidationResult(
                isValid: true,
                suggestedAddress: nil,
                confidence: 0.95,
                errors: []
            )
            
        case .validWithSuggestion:
            let suggestion = generateSuggestedAddress(from: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: suggestion,
                confidence: 0.85,
                errors: []
            )
            
        case .invalidAddress:
            let errors = generateValidationErrors(for: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: nil,
                confidence: 0.2,
                errors: errors
            )
            
        case .partialMatch:
            let suggestion = generateSuggestedAddress(from: address)
            return AddressValidationResult(
                isValid: false,
                suggestedAddress: suggestion,
                confidence: 0.7,
                errors: [.invalidZipCode]
            )
        }
    }
    
    private func generateSuggestedAddress(from original: Address) -> Address {
        var suggestedStreet = original.street
        var suggestedZip = original.zipCode
        
        if original.street.contains("123") {
            suggestedStreet = original.street.replacingOccurrences(of: "123", with: "125")
        }
        
        if original.zipCode == "94105" {
            suggestedZip = "94104"
        }
        
        return Address(
            id: UUID().uuidString,
            firstName: original.firstName,
            lastName: original.lastName,
            street: suggestedStreet,
            street2: original.street2,
            city: original.city,
            state: original.state,
            zipCode: suggestedZip,
            country: original.country,
            isDefault: original.isDefault,
            type: original.type
        )
    }
    
    private func generateValidationErrors(for address: Address) -> [AddressValidationError] {
        var errors: [AddressValidationError] = []
        
        if address.street.count < 5 {
            errors.append(.invalidStreetAddress)
        }
        
        if address.zipCode.count != 5 || !address.zipCode.allSatisfy(\.isNumber) {
            errors.append(.invalidZipCode)
        }
        
        if address.city.count < 2 {
            errors.append(.invalidCity)
        }
        
        if address.state.count != 2 {
            errors.append(.invalidState)
        }
        
        if errors.isEmpty {
            errors.append(.unserviceableArea)
        }
        
        return errors
    }
    
    private func generateMockSuggestions(for query: String) -> [AddressSuggestion] {
        let commonStreets = [
            "Main Street", "Oak Street", "First Street", "Second Street",
            "Park Avenue", "Elm Street", "Washington Street", "Lincoln Avenue"
        ]
        
        let cities = [
            ("San Francisco", "CA", "94105"),
            ("New York", "NY", "10001"),
            ("Los Angeles", "CA", "90210"),
            ("Chicago", "IL", "60601"),
            ("Houston", "TX", "77001"),
            ("Phoenix", "AZ", "85001")
        ]
        
        var suggestions: [AddressSuggestion] = []
        
        for _ in 1...Int.random(in: 3...8) {
            let street = commonStreets.randomElement()!
            let (city, state, zipCode) = cities.randomElement()!
            let number = Int.random(in: 100...9999)
            
            let suggestion = AddressSuggestion(
                formattedAddress: "\(number) \(street), \(city), \(state) \(zipCode)",
                street: "\(number) \(street)",
                street2: nil,
                city: city,
                state: state,
                zipCode: zipCode,
                country: "US",
                confidence: Double.random(in: 0.7...0.95)
            )
            
            suggestions.append(suggestion)
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    enum ValidationScenario: CaseIterable {
        case valid
        case validWithSuggestion
        case invalidAddress
        case partialMatch
    }
}

class EmbraceManager {
    static let shared = EmbraceManager()
    private init() {}
    
    func startSpan(name: String, type: SpanType) -> MockSpan? {
        return MockSpan(name: name, type: type)
    }
    
    func logMessage(_ message: String, severity: LogSeverity, properties: [String: Any] = [:]) {
        print("📝 [\(severity.rawValue.uppercased())] \(message)")
        if !properties.isEmpty {
            print("   Properties: \(properties)")
        }
    }
    
    enum SpanType {
        case performance
        case network
    }
    
    enum LogSeverity: String {
        case info
        case warning
        case error
    }
}

class MockSpan {
    let name: String
    let type: EmbraceManager.SpanType
    private var attributes: [String: Any] = [:]
    
    init(name: String, type: EmbraceManager.SpanType) {
        self.name = name
        self.type = type
        print("🔍 Started span: \(name)")
    }
    
    func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
    func setStatus(_ status: SpanStatus, description: String = "") {
        print("📊 Span \(name) status: \(status)")
        if !description.isEmpty {
            print("   Description: \(description)")
        }
    }
    
    func end() {
        print("✅ Ended span: \(name)")
        if !attributes.isEmpty {
            print("   Attributes: \(attributes)")
        }
    }
    
    enum SpanStatus {
        case ok
        case error
    }
}