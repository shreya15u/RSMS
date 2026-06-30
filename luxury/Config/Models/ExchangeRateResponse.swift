import Foundation

struct ExchangeRateResponse: Codable {
    let result: String
    let baseCode: String
    
    private let _conversionRates: [String: Double]?
    private let _rates: [String: Double]?
    
    var conversionRates: [String: Double] {
        return _conversionRates ?? _rates ?? [:]
    }
    
    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case _conversionRates = "conversion_rates"
        case _rates = "rates"
    }
}
