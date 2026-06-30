//
//  EndlessAisleModels.swift
//  luxury
//
//  Created by Nalinish Ranjan on 26/05/26.
//

import Foundation

public enum EndlessAisle {
    public struct Item: Identifiable, Codable, Sendable, Hashable, Equatable {
        public let id: UUID
        public let name: String
        public let sku: String
        public let price: Double
        public let localQuantity: Int
        
        public init(id: UUID, name: String, sku: String, price: Double, localQuantity: Int) {
            self.id = id
            self.name = name
            self.sku = sku
            self.price = price
            self.localQuantity = localQuantity
        }
    }
    
    public struct BoutiqueStock: Identifiable, Codable, Sendable, Hashable, Equatable {
        public let id: UUID
        public let name: String
        public let city: String
        public let quantity: Int
        
        public init(id: UUID, name: String, city: String, quantity: Int) {
            self.id = id
            self.name = name
            self.city = city
            self.quantity = quantity
        }
    }
    
    public enum RequestState: String, Codable, Sendable, CaseIterable, Hashable {
        case checking
        case localInStock
        case noStockAnywhere
        case pendingBoutiqueManagerApproval
        case pendingSourceBoutiqueApproval
        case pendingSourceDispatch
        case dispatched
        case arrived
        case received
    }
    
    public struct SourcingRequest: Identifiable, Codable, Sendable, Hashable, Equatable {
        public let id: UUID
        public let originalOrderId: UUID?
        public let item: Item
        public let sourceBoutiqueId: UUID?
        public let destinationBoutiqueId: UUID?
        public let sourceStore: String
        public let destinationStore: String
        public let serialNumber: String?
        public var status: RequestState
        public var history: [String]
        public var lastUpdated: Date
        
        public init(id: UUID, originalOrderId: UUID?, item: Item, sourceBoutiqueId: UUID?, destinationBoutiqueId: UUID?, sourceStore: String, destinationStore: String, serialNumber: String?, status: RequestState, history: [String], lastUpdated: Date) {
            self.id = id
            self.originalOrderId = originalOrderId
            self.item = item
            self.sourceBoutiqueId = sourceBoutiqueId
            self.destinationBoutiqueId = destinationBoutiqueId
            self.sourceStore = sourceStore
            self.destinationStore = destinationStore
            self.serialNumber = serialNumber
            self.status = status
            self.history = history
            self.lastUpdated = lastUpdated
        }
    }
}
