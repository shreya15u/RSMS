//
//  CurrencyManager.swift
//  luxury
//
//  Created by Aditya Chauhan on 25/05/26.
//

import SwiftUI
import Observation


@Observable
final class CurrencyManager {
    static let shared = CurrencyManager()
    
    private let defaults = UserDefaults.standard
    private let currencyKey = "AppGlobalCurrency"
    
    var currentCurrency: String {
        didSet {
            defaults.set(currentCurrency, forKey: currencyKey)
        }
    }
    
    var symbol: String {
        symbol(for: currentCurrency)
    }
    
    private var rates: [String: Double] = ["INR": 1.0]
    

    var availableCurrencies: [String] {
        Array(rates.keys).sorted()
    }
    
    private var symbolCache: [String: String] = [:]
    
    func symbol(for code: String) -> String {
        if let cached = symbolCache[code] { return cached }
        
        let commonSymbols: [String: String] = [
            "USD": "$", "EUR": "€", "GBP": "£", "JPY": "¥",
            "INR": "₹", "AUD": "$", "CAD": "$", "CHF": "CHF", "CNY": "¥"
        ]
        if let sym = commonSymbols[code] {
            symbolCache[code] = sym
            return sym
        }
        
        for id in Locale.availableIdentifiers {
            let locale = Locale(identifier: id)
            if locale.currency?.identifier == code {
                if let symbol = locale.currencySymbol, symbol != code {
                    symbolCache[code] = symbol
                    return symbol
                }
            }
        }
        
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code]))
        let result = locale.currencySymbol ?? code
        symbolCache[code] = result
        return result
    }
    private init() {
        if let data = defaults.data(forKey: "CachedCurrencyRates"),
           let cachedRates = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.rates = cachedRates
        }
        
        if let saved = UserDefaults.standard.string(forKey: currencyKey) {
            self.currentCurrency = saved
        } else {
            self.currentCurrency = "INR"
        }
        
        Task {
            await fetchRates()
        }
    }
    
    func fetchRates() async {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/INR") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            if let response = try? decoder.decode(ExchangeRateResponse.self, from: data), response.result == "success" {
                if let data = try? JSONEncoder().encode(response.conversionRates) {
                    self.defaults.set(data, forKey: "CachedCurrencyRates")
                }
                await MainActor.run {
                    self.rates = response.conversionRates
                }
            }
        } catch {
            print("Failed to fetch exchange rates: \(error)")
        }
    }
    
    func convertedAmount(fromINR amount: Double) -> Double {
        let rate = rates[currentCurrency] ?? 1.0
        return amount * rate
    }
    
    func baseAmount(fromConverted convertedAmount: Double) -> Double {
        let rate = rates[currentCurrency] ?? 1.0
        return rate > 0 ? convertedAmount / rate : convertedAmount
    }
    
    func format(amount amountInINR: Double) -> String {
        let converted = convertedAmount(fromINR: amountInINR)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if currentCurrency == "INR" {
            formatter.locale = Locale(identifier: "en_IN")
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        formatter.currencyCode = currentCurrency
        formatter.currencySymbol = symbol(for: currentCurrency)
        formatter.maximumFractionDigits = currentCurrency == "JPY" ? 0 : 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: converted)) ?? "\(symbol(for: currentCurrency))\(converted)"
    }
    
    func formatCompact(amount amountInINR: Double) -> String {
        let converted = convertedAmount(fromINR: amountInINR)
        
        if currentCurrency == "INR" {
            if converted >= 10_000_000 {
                let formatted = String(format: "%.2f", converted / 10_000_000.0)
                return "\(symbol(for: currentCurrency))\(formatted) Cr"
            } else if converted >= 1_00_000 {
                let formatted = String(format: "%.2f", converted / 100_000.0)
                return "\(symbol(for: currentCurrency))\(formatted) L"
            }
        } else {
            if converted >= 1_000_000 {
                let formatted = String(format: "%.2f", converted / 1_000_000.0)
                return "\(symbol(for: currentCurrency))\(formatted)M"
            } else if converted >= 1_000 {
                let formatted = String(format: "%.2f", converted / 1_000.0)
                return "\(symbol(for: currentCurrency))\(formatted)K"
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if currentCurrency == "INR" {
            formatter.locale = Locale(identifier: "en_IN")
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        formatter.currencyCode = currentCurrency
        formatter.currencySymbol = symbol(for: currentCurrency)
        formatter.maximumFractionDigits = currentCurrency == "JPY" ? 0 : 2
        formatter.minimumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: converted)) ?? "\(symbol(for: currentCurrency))\(converted)"
    }
}
