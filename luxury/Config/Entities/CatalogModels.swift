//
//  CatalogModels.swift
//  luxury
//

import Foundation

enum CatalogCategory: String, Codable, CaseIterable, Equatable, Hashable {
    case watches = "Watches"
    case jewelry = "Jewelry"
    case bags = "Bags"
    case accessories = "Accessories"
    case apparel = "Apparel"
    case shoes = "Shoes"
    case other = "Other"
}

enum CatalogStatus: String, Codable, CaseIterable, Equatable, Hashable {
    case active = "Active"
    case paused = "Paused"
    case archived = "Archived"
}

struct CatalogEntity: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let catalogId: String
    let name: String
    let description: String
    let brand: String
    let category: CatalogCategory
    let amount: Double
    let barCode: String
    var status: CatalogStatus
    var productImages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, brand, category, amount, status
        case catalogId = "catalog_id"
        case barCode = "bar_code"
        case productImages = "product_images"
    }
    
    
    var formattedPrice: String {
        return "\(CurrencyManager.shared.symbol)\(Int(amount))"
    }
}
