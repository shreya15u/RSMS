//
//  InventoryModels.swift
//  luxury
//
//  Created by Nalinish Ranjan on 22/05/26.
//

import Foundation

struct InventoryItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let storeId: UUID
    let skuId: UUID
    var quantity: Int
    var productAvailable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, quantity
        case storeId = "store_id"
        case skuId = "sku_id"
        case productAvailable = "product_available"
    }
}

// Composite model for the Corporate Admin dashboard UI
struct ProductInventorySummary: Identifiable, Equatable, Hashable {
    var id: UUID { product.id }
    let product: CatalogEntity
    let totalQuantity: Int
    let locations: [LocationInventoryDetail]
    
    var alertStatus: StockAlertStatus {
        if totalQuantity == 0 {
            return .outOfStock
        } else if totalQuantity < 5 {
            return .lowStock
        }
        return .optimal
    }
}

struct LocationInventoryDetail: Identifiable, Equatable, Hashable {
    var id: UUID { storeId }
    let storeId: UUID
    let storeName: String
    let quantity: Int
    let isAvailable: Bool
}

enum StockAlertStatus: String, CaseIterable {
    case optimal = "Optimal"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
}

enum InventoryUnitStatus: String, Codable, CaseIterable, Equatable, Hashable {
    case available = "Available"
    case reserved = "Reserved"
    case sold = "Sold"
    case inTransit = "In Transit"
}

struct InventoryUnitEntity: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let catalogId: UUID
    let boutiqueId: UUID
    let serialNumber: String
    var status: InventoryUnitStatus
    let createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case catalogId = "catalog_id"
        case boutiqueId = "boutique_id"
        case serialNumber = "serial_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
